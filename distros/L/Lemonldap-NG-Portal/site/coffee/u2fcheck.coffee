###
LemonLDAP::NG U2F verify script
###

check = ->
	u2f.sign window.datas.appId, window.datas.challenge, window.datas.registeredKeys, (data) ->
		$('#verify-data').val JSON.stringify data
		$('#verify-challenge').val window.datas.challenge
		$('#verify-form').submit()

$(document).ready ->
	setTimeout check, 1000
