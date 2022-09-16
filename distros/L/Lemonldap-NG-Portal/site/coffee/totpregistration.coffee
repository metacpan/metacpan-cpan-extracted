###
LemonLDAP::NG TOTP registration script
###

setMsg = (msg, level) ->
	$('#msg').attr 'trspan', msg
	$('#msg').html window.translate msg
	$('#color').removeClass 'message-positive message-warning message-danger alert-success alert-warning alert-danger'
	$('#color').addClass "message-#{level}"
	level = 'success' if level == 'positive'
	$('#color').addClass "alert-#{level}"
	$('#msg').attr 'role', (if level == 'danger' then 'alert' else 'status')

displayError = (j, status, err) ->
	console.log 'Error', err
	res = JSON.parse j.responseText
	if res and res.error
		res = res.error.replace(/.* /, '')
		console.log 'Returned error', res
		setMsg res, 'warning'

token=''

getKey = () ->
	setMsg 'yourTotpKey', 'warning'
	$.ajax
		type: "POST",
		url: "#{portal}/2fregisters/totp/getkey"
		dataType: 'json'
		error: displayError
		# Display key and QR code
		success: (data) ->
			if data.error
				if data.error.match /totpExistingKey/
					$("#divToHide").hide()
				return setMsg data.error, 'warning'
			unless data.portal and data.user and data.secret
				return setMsg('PE24', 'danger')

			# Generate OTP url
			$("#divToHide").show()
			s = "otpauth://totp/#{escape(data.portal)}:#{escape(data.user)}?secret=#{data.secret}&issuer=#{escape(data.portal)}"
			if data.digits != 6
				s += "&digits=#{data.digits}"
			if data.interval != 30
				s += "&period=#{data.interval}"
			# Generate QR code
			qr = new QRious
				element: document.getElementById('qr'),
				value: s
				size:150
			# Display serialized key
			secret = data.secret || ""
			$('#secret').text(secret.toUpperCase().replace(/(.{4})/g, '$1 ').trim())
			# Show message (warning level if key is new)
			if data.newkey
				setMsg 'yourNewTotpKey', 'warning'
			else
				setMsg 'yourTotpKey', 'success'
			token = data.token

verify = ->
	val = $('#code').val()
	unless val
		setMsg 'totpMissingCode', 'warning'
		$("#code").focus()
	else
		$.ajax
			type: "POST",
			url: "#{portal}/2fregisters/totp/verify"
			dataType: 'json'
			data:
				token: token
				code: val
				TOTPName: $('#TOTPName').val()
			error: displayError
			success: (data) ->
				if data.error
					if data.error.match /bad(Code|Name)/
						setMsg data.error, 'warning'
					else
						setMsg data.error, 'danger'
				else
					$(document).trigger "mfaAdded", [ { "type": "totp" } ]
					setMsg 'yourKeyIsRegistered', 'success'					
					
$(document).ready ->
	getKey()
	$('#verify').on 'click', () -> verify()
