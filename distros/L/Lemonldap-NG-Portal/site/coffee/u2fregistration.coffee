###
LemonLDAP::NG U2F registration script
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

# Registration function (launched by "register" button)
register = ->
	# 1 get registration token
	$.ajax
		type: "POST",
		url: "#{portal}2fregisters/u/register"
		data: {}
		dataType: 'json'
		error: displayError
		success: (ch) ->
			# 2 build response
			request = [
				challenge: ch.challenge
				version: ch.version
			]
			setMsg 'touchU2fDevice', 'positive'
			$('#u2fPermission').show()
			u2f.register ch.appId, request, [], (data) ->
				$('#u2fPermission').hide()
				# Handle errors
				if data.errorCode
					setMsg data.error, 'warning'
				else
					# 3 send response
					$.ajax
						type: "POST"
						url: "#{portal}2fregisters/u/registration"
						data: 
							registration: JSON.stringify data
							challenge: JSON.stringify ch
							keyName: $('#keyName').val()
						dataType: 'json'
						success: (resp) ->
							if resp.error
								if resp.error.match /badName/
									setMsg resp.error, 'warning'
								else setMsg 'u2fFailed', 'danger'
							else if resp.result
								$(document).trigger "mfaAdded", [ { "type": "u" } ]
								setMsg 'yourKeyIsRegistered', 'positive'
						error: displayError

# Verification function (launched by "verify" button)
verify = ->
	# 1 get challenge
	$.ajax
		type: "POST",
		url: "#{portal}2fregisters/u/verify"
		data: {}
		dataType: 'json'
		error: displayError
		success: (ch) ->
			# 2 build response
			setMsg 'touchU2fDevice', 'positive'
			u2f.sign ch.appId, ch.challenge, ch.registeredKeys, (data) ->
				# Handle errors
				if data.errorCode
					setMsg 'unableToGetKey', 'warning'
				else
					# 3 send response
					$.ajax
						type: "POST"
						url: "#{portal}2fregisters/u/signature"
						data:
							signature: JSON.stringify data
							challenge: ch.challenge
						dataType: 'json'
						success: (resp) ->
							if resp.error
								setMsg 'u2fFailed', 'danger'
							else if resp.result
								setMsg 'yourKeyIsVerified', 'positive'
						error: (j, status, err) ->
							console.log 'error', err

# Register "click" events
$(document).ready ->
	$('#u2fPermission').hide()
	$('#register').on 'click', register
	$('#verify').on 'click', verify
	$('#goback').attr 'href', portal
