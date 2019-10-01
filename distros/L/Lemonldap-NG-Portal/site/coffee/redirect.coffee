document.onreadystatechange = () ->
	if document.readyState == "complete"
		try
			redirect = document.getElementById('redirect').textContent.replace /\s/g, ''
		catch
			redirect = document.getElementById('redirect').innerHTML.replace /\s/g, ''
		if redirect
			if redirect == 'form'
				document.getElementById('form').submit()
			else
				document.location.href = redirect
		else
			console.log 'No redirection !'
