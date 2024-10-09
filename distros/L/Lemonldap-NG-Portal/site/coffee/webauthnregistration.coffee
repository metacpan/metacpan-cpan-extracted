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


# Registration function (launched by "register" button)
register = ->
	if !webauthnJSON.supported()
		setMsg 'webAuthnUnsupported', 'warning'
		return

	# 1 get registration token
	$.ajax
		type: "POST",
		url: "#{portal}2fregisters/webauthn/registrationchallenge"
		data: {}
		dataType: 'json'
		error: displayError
		success: (ch) ->
			# 2 build response
			request = {publicKey: ch.request}
			e = jQuery.Event( "webauthnRegistrationAttempt" )
			$(document).trigger e
			if !e.isDefaultPrevented()
				setMsg 'webAuthnRegisterInProgress', 'warning'
				$('#u2fPermission').show()
				webauthnJSON.create request
				. then (response) ->
					e = jQuery.Event( "webauthnRegistrationSuccess" )
					$(document).trigger e, [ response ]
					if !e.isDefaultPrevented()
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
									e = jQuery.Event( "mfaAdded" )
									$(document).trigger e, [ { "type": "webauthn" } ]
									if !e.isDefaultPrevented()
										window.location.href = window.portal + "2fregisters?continue=1"
							error: displayError
				, (error) ->
					e = jQuery.Event( "webauthnRegistrationFailure" )
					$(document).trigger e, [ error ]
					if !e.isDefaultPrevented()
						setMsg 'webAuthnBrowserFailed', 'danger'

# Verification function (launched by "verify" button)
verify = ->

	if !webauthnJSON.supported()
		setMsg 'webAuthnUnsupported', 'warning'
		return
	# 1 get challenge
	$.ajax
		type: "POST",
		url: "#{portal}2fregisters/webauthn/verificationchallenge"
		data: {}
		dataType: 'json'
		error: displayError
		success: (ch) ->
			# 2 build response
			request = {publicKey: ch.request}
			setMsg 'webAuthnBrowserInProgress', 'warning'
			webauthnJSON.get request
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
				setMsg 'webAuthnBrowserFailed', 'danger'

# Register "click" events
$(document).ready ->
	$('#u2fPermission').hide()
	$('#register').on 'click', register
	$('#verify').on 'click', verify
	setTimeout register, 1000
	$('#retrybutton').on 'click', register
	$('#goback').attr 'href', portal
