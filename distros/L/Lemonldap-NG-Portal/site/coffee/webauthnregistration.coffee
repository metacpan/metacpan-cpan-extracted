###
LemonLDAP::NG WebAuthn registration script
###

setMsg = (msg, level) ->
	$('#msg').attr 'trspan', msg
	$('#msg').html window.translate msg
	$('#color').removeClass 'message-positive message-warning message-danger alert-success alert-warning alert-danger'
	$('#color').addClass "message-#{level}"
	level = 'success' if level == 'positive'
	$('#color').addClass "alert-#{level}"

displayError = (j, status, err) ->
	console.log 'Error', err
	res = JSON.parse j.responseText
	if res and res.error
		res = res.error.replace(/.* /, '')
		console.log 'Returned error', res
		setMsg res, 'danger'

webAuthnError = (error) ->
	switch (error.name)
		when 'unsupported' then setMsg 'webAuthnUnsupported', 'warning'
		else setMsg 'webAuthnBrowserFailed', 'danger'

# Registration function (launched by "register" button)
register = ->
	# 1 get registration token
	$.ajax
		type: "POST",
		url: "#{portal}2fregisters/webauthn/registrationchallenge"
		data: {}
		dataType: 'json'
		error: displayError
		success: (ch) ->
			# 2 build response
			request = ch.request 
			setMsg 'webAuthnRegisterInProgress', 'warning'
			$('#u2fPermission').show()
			WebAuthnUI.WebAuthnUI.createCredential request
			. then (response) ->
				$.ajax
					type: "POST"
					url: "#{portal}2fregisters/webauthn/registration"
					data:
						state_id: ch.state_id
						credential: JSON.stringify response
						keyName: $('#keyName').val()
					dataType: 'json'
					success: (resp) ->
						if resp.error
							if resp.error.match /badName/
								setMsg resp.error, 'danger'
							else setMsg 'webAuthnRegisterFailed', 'danger'
						else if resp.result
							$(document).trigger "mfaAdded", [ { "type": "webauthn" } ]
							setMsg 'yourKeyIsRegistered', 'positive'
					error: displayError
			. catch (error) ->
				webAuthnError(error)

# Verification function (launched by "verify" button)
verify = ->
	# 1 get challenge
	$.ajax
		type: "POST",
		url: "#{portal}2fregisters/webauthn/verificationchallenge"
		data: {}
		dataType: 'json'
		error: displayError
		success: (ch) ->
			# 2 build response
			request = ch.request
			setMsg 'webAuthnBrowserInProgress', 'warning'
			WebAuthnUI.WebAuthnUI.getCredential request
			. then (response) ->
				$.ajax
					type: "POST"
					url: "#{portal}2fregisters/webauthn/verification"
					data:
						state_id: ch.state_id
						credential: JSON.stringify response
					dataType: 'json'
					success: (resp) ->
						if resp.error
							setMsg 'webAuthnFailed', 'danger'
						else if resp.result
							setMsg 'yourKeyIsVerified', 'positive'
					error: displayError
			. catch (error) ->
				webAuthnError(error)

# Register "click" events
$(document).ready ->
	$('#u2fPermission').hide()
	$('#register').on 'click', register
	$('#verify').on 'click', verify
	$('#goback').attr 'href', portal
