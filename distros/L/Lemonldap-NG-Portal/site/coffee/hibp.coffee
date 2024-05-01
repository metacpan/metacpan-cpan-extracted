$(document).on 'checkpassword', (event, context) ->

	password = context.password
	evType = context.evType
	setResult = context.setResult

	# if checkHIBP is enabled
	if $('#ppolicy-checkhibp-feedback').length > 0
		newpasswordVal = $( "#newpassword" ).val()
		if( newpasswordVal.length >= 5 )
			# don't check HIBP at each keyup, but only when input focuses out
			if evType == "focusout"
				setResult('ppolicy-checkhibp-feedback', "waiting")
				$.ajax
					dataType: "json"
					url: "/checkhibp"
					method: "POST"
					data: { "password": btoa(newpasswordVal) }
					context: document.body
					success: (data) ->
						code = data.code
						msg = data.message
						if code != undefined
							if parseInt(code) == 0
								# password ok
								setResult('ppolicy-checkhibp-feedback', "good")
							else if parseInt(code) == 2
								# password compromised
								setResult('ppolicy-checkhibp-feedback', "bad")
							else
								# unexpected error
								console.log 'checkhibp: backend error: ', msg
								setResult('ppolicy-checkhibp-feedback', "unknown" )
					error: (j, status, err) ->
						console.log 'checkhibp: frontend error: ', err  if err
						res = JSON.parse j.responseText if j
						if res and res.error
							console.log 'checkhibp: returned error: ', res
		else
			# Check not performed yet
			setResult('ppolicy-checkhibp-feedback', "unknown" )
