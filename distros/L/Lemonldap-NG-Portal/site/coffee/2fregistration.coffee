###
LemonLDAP::NG 2F registration script
###

setMsg = (msg, level) ->
	$('#msg').attr 'trspan', msg
	$('#msg').html window.translate msg
	$('#color').removeClass 'message-positive message-warning alert-success alert-warning'
	$('#color').addClass "message-#{level}"
	level = 'success' if level == 'positive'
	$('#color').addClass "alert-#{level}"
	$('#color').attr "role", "status"

displayError = (j, status, err) ->
	console.log 'Error', err
	res = JSON.parse j.responseText
	if res and res.error
		res = res.error.replace /.* /, ''
		console.log 'Returned error', res
		if res.match /module/
			setMsg 'notAuthorized', 'warning'
		else
			setMsg res, 'warning'

# Delete function (launched by "delete" button)
delete2F = (device, epoch, prefix) ->
		# Only needed in case pre 2.0.16 templates are used
		if (!prefix)
			if device == 'U2F'
				prefix = 'u'
			else if device == 'UBK'
					prefix = 'yubikey'
			else if device == 'TOTP'
					prefix = 'totp'
			else if device == 'WebAuthn'
					prefix = 'webauthn'
			# Falling back is not likely to be very successful...
			else prefix = device.toLowerCase()
		$.ajax
			type: "POST"
			url: "#{portal}2fregisters/#{prefix}/delete"
			data:
				epoch: epoch
			dataType: 'json'
			error: displayError
			success: (resp) ->
				if resp.error
					if resp.error.match /notAuthorized/
						setMsg 'notAuthorized', 'warning'
					else setMsg 'unknownAction', 'warning'
				else if resp.result
					$("#delete-#{epoch}").hide()
					$(document).trigger "mfaDeleted", [ { "type": device, "epoch": epoch } ]
					setMsg 'yourKeyIsUnregistered', 'positive'
			error: displayError

# Register "click" events
$(document).ready ->
	$('body').on 'click', '.remove2f', () -> delete2F ( $(this).attr 'device' ), ( $(this).attr 'epoch' ), ( $(this).attr 'prefix' )
	$('#goback').attr 'href', portal
	$(".data-epoch").each ->
		myDate = new Date($(this).text() * 1000)
		$(this).text(myDate.toLocaleString())
