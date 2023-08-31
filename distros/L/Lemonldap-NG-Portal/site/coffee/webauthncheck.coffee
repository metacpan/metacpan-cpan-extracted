###
LemonLDAP::NG WebAuthn verify script
###

setMsg = (msg, level) ->
	$('#msg').attr 'trspan', msg
	$('#msg').html window.translate msg
	$('#color').removeClass 'message-positive message-warning message-danger alert-success alert-warning alert-danger'
	$('#color').addClass "message-#{level}"
	level = 'success' if level == 'positive'
	$('#color').addClass "alert-#{level}"

webAuthnError = (error) ->
	switch (error.name)
		when 'unsupported' then setMsg 'webAuthnUnsupported', 'warning'
		else setMsg 'webAuthnBrowserFailed', 'danger'

check = ->
	e = jQuery.Event( "webauthnAttempt" )
	$(document).trigger e
	if !e.isDefaultPrevented()
		setMsg 'webAuthnBrowserInProgress', 'warning'
		request = window.datas.request
		WebAuthnUI.WebAuthnUI.getCredential request
		. then (response) ->
			e = jQuery.Event( "webauthnSuccess" )
			$(document).trigger e, [ response ]
			if !e.isDefaultPrevented()
				$('#credential').val JSON.stringify response
				$('#verify-form').submit()
		. catch (error) ->
			e = jQuery.Event( "webauthnFailure" )
			$(document).trigger e, [ error ]
			if !e.isDefaultPrevented()
				webAuthnError(error)

$(document).ready ->
	setTimeout check, 1000
	$('#retrybutton').on 'click', check
