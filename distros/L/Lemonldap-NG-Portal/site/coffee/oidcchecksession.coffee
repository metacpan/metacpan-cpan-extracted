values = {}

$(document).ready ->
	# Import application/init variables
	$("script[type='application/init']").each ->
		try
			tmp = JSON.parse $(this).text()
			for k of tmp
				values[k] = tmp[k]
				#console.log 'values=', values[k]
		catch e
			console.log 'Parsing error', e
	# Initialize JS communication channel
	window.addEventListener "message", (e) ->
			message = e.data
			console.log 'message=', message
			client_id = decodeURIComponent message.split(' ')[0]
			#console.log 'client_id=', client_id
			session_state = decodeURIComponent message.split(' ')[1]
			#console.log 'session_state=', session_state
			salt = decodeURIComponent session_state.split('.')[1]
			#console.log 'salt=', salt
			# hash ??????
			#ss = hash.toString(CryptoJS.enc.Base64) + '.'  + salt
			ss = btoa(client_id + ' ' + e.origin + ' ' + salt) + '.'  + salt
			#word = CryptoJS.enc.Utf8.parse(client_id + ' ' + e.origin + ' ' + salt)
			#ss = CryptoJS.enc.Base64.stringify(word) + '.' + salt
			if session_state == ss
				stat = 'unchanged'
			else
				stat = 'changed'
			e.source.postMessage stat, e.origin
	, false
