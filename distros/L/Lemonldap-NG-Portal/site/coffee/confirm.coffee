# Timer for confirmation page

i = 5
timerIsEnabled = 0

go = () ->
	$("#form").submit() if timerIsEnabled

timer = () ->
	h = $('#timer').html()
	if h
		timerIsEnabled = 1
		i-- if i>0
		h = h.replace /\d+/, i
		$('#timer').html h
		setTimeout timer, 1000

$(document).ready ->
	setTimeout go, 30000
	setTimeout timer, 1000
	$("#refuse").on 'click', () ->
		$("#confirm").attr "value", $(this).attr("val")
