isAlphaNumeric = (chr) ->
	code = chr.charCodeAt(0)
	if code > 47 and code < 58 or code > 64 and code < 91 or code > 96 and code < 123
		return true
	false

$(document).on 'checkpassword', (event, context) ->

	password = context.password
	evType = context.evType
	setResult = context.setResult

	report = (result, id) ->
		if result
			setResult(id, "good");
		else
			setResult(id, "bad");

	if window.datas.ppolicy.minsize > 0
		report( password.length >= window.datas.ppolicy.minsize, 'ppolicy-minsize-feedback' )
	if window.datas.ppolicy.maxsize > 0
		report( password.length <= window.datas.ppolicy.maxsize, 'ppolicy-maxsize-feedback' )
	if window.datas.ppolicy.minupper > 0
		upper = password.match(/[A-Z]/g)
		report( upper and upper.length >= window.datas.ppolicy.minupper, 'ppolicy-minupper-feedback' )
	if window.datas.ppolicy.minlower > 0
		lower = password.match(/[a-z]/g)
		report( lower and lower.length >= window.datas.ppolicy.minlower, 'ppolicy-minlower-feedback')
	if window.datas.ppolicy.mindigit > 0
		digit = password.match(/[0-9]/g)
		report( digit and digit.length >= window.datas.ppolicy.mindigit, 'ppolicy-mindigit-feedback')

	if window.datas.ppolicy.allowedspechar
		nonwhitespechar = window.datas.ppolicy.allowedspechar.replace(/\s/g, '')
		nonwhitespechar = nonwhitespechar.replace(/<space>/g, ' ')
		hasforbidden = false
		i = 0
		len = password.length
		while i < len
			if !isAlphaNumeric(password.charAt(i))
				if nonwhitespechar.indexOf(password.charAt(i)) < 0
					hasforbidden = true
			i++
		report( hasforbidden == false, 'ppolicy-allowedspechar-feedback' )

	if window.datas.ppolicy.minspechar > 0 and window.datas.ppolicy.allowedspechar
		numspechar = 0
		nonwhitespechar = window.datas.ppolicy.allowedspechar.replace(/\s/g, '')
		nonwhitespechar = nonwhitespechar.replace(/<space>/g, ' ')
		i = 0
		while i < password.length
			if nonwhitespechar.indexOf(password.charAt(i)) >= 0
				numspechar++
			i++
		report( numspechar >= window.datas.ppolicy.minspechar, 'ppolicy-minspechar-feedback')

	if window.datas.ppolicy.minspechar > 0 and !window.datas.ppolicy.allowedspechar
		numspechar = 0
		i = 0
		while i < password.length
			numspechar++ if !isAlphaNumeric(password.charAt(i))
			i++
		report( numspechar >= window.datas.ppolicy.minspechar, 'ppolicy-minspechar-feedback')
