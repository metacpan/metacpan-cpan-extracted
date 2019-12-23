# Timer for globalLogout page

i = 30

go = () ->
	$("#globallogout").submit()

timer = () ->
	h = $('#timer').html()
	i-- if i>0
	h = h.replace /\d+/, i
	$('#timer').html(h)
	window.setTimeout timer, 1000

$(document).ready ->
		window.setTimeout go, 30000
		window.setTimeout timer, 1000
