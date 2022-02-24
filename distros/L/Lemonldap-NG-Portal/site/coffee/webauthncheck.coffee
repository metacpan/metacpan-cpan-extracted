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
	setMsg 'webAuthnBrowserInProgress', 'warning'
	request = window.datas.request
	WebAuthnUI.WebAuthnUI.getCredential request
	. then (response) ->
		$('#credential').val JSON.stringify response
		$('#verify-form').submit()
	. catch (error) ->
		webAuthnError(error)

$(document).ready ->
	setTimeout check, 1000
	$('#retrybutton').on 'click', check
