document.onreadystatechange = () ->
	if document.readyState == "complete"
		redirect = document.getElementById('redirect').textContent.replace /\s/g, ''
		if redirect
			if redirect == 'form'
				document.getElementById('form').submit()
			else
				document.location.href = redirect
		else
			console.log 'No redirection !'
