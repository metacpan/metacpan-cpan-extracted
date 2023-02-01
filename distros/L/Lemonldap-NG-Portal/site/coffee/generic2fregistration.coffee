###
LemonLDAP::NG Generic registration script
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

verify = ->
	generic = $('#generic').val()
	prefix = window.datas.prefix
	if !generic
		setMsg 'PE79', 'warning'
		$('#generic').focus()
	else
		$.ajax
			type: 'POST'
			url: portal + "/2fregisters/#{prefix}/sendcode"
			dataType: 'json'
			data:
				generic: generic
			error: displayError
			success: (data) ->
				if data.error
					if data.error.match(/PE79/)
						setMsg data.error, 'warning'
					else
						setMsg data.error, 'danger'
				else
					$('#token').val data.token
					setMsg 'genericCheckCode', 'success'

register = ->
	generic = $('#generic').val()
	genericname = $('#genericname').val()
	genericcode = $('#code').val()
	prefix = window.datas.prefix
	token = $('#token').val()
	if !generic
		setMsg 'PE79', 'warning'
		$('#generic').focus()
	else
		$.ajax
			type: 'POST'
			url: portal + "/2fregisters/#{prefix}/verify"
			dataType: 'json'
			data:
				generic: generic
				genericname: genericname
				genericcode: genericcode
				token: token
			error: displayError
			success: (data) ->
				if data.error
					if data.error.match(/mailNotSent/)
						setMsg data.error, 'warning'
					else
						setMsg data.error, 'danger'
				else
					$(document).trigger "mfaAdded", [ { "type": prefix } ]
					setMsg 'genericRegistered', 'success'

# Register "click" events
$(document).ready ->
	$('#verify').on 'click', verify
	$('#register').on 'click', register
