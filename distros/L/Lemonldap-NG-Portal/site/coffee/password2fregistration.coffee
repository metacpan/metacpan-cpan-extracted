###
LemonLDAP::NG Password 2FA registration script
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

register = ->
	password = $('#password2f').val()
	passwordverify = $('#password2fverify').val()
	if !password
		setMsg 'PE79', 'warning'
		$('#password').focus()
	else
		$.ajax
			type: 'POST'
			url: portal + '/2fregisters/password/verify'
			dataType: 'json'
			data:
				password: password
				passwordverify: passwordverify
			error: displayError
			success: (data) ->
				if data.error
					if data.error.match(/PE34/)
						setMsg data.error, 'warning'
					else
						setMsg data.error, 'danger'
				else
					$(document).trigger "mfaAdded", [ { "type": "password" } ]
					setMsg 'yourPasswordIsRegistered', 'success'

# Register "click" events
$(document).ready ->
	$('#register').on 'click', register
