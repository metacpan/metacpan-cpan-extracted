$(document).ready ->
	if window.requestIdleCallback
		requestIdleCallback () ->
			go()
	else
		setTimeout go, 500

go = () ->
	Fingerprint2.get (components) ->
		values = components.map (component) =>
			component.value
		result = Fingerprint2.x64hash128(values.join(''), 31)
		$('#fg').attr "value", result
		$('#form').submit()
