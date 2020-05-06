# Timer for information page

i = 30
_go = 1

stop = () ->
	_go = 0
	$('#divToHide').hide();
	$('#wait').hide();

go = () ->
	$("#form").submit() if _go

timer = () ->
	h = $('#timer').html()
	i-- if i>0
	h = h.replace /\d+/, i
	$('#timer').html(h)
	window.setTimeout timer, 1000

#$(document).ready ->
$(window).on 'load', () ->
	if window.datas['activeTimer']
		window.setTimeout go, 30000
		window.setTimeout timer, 1000
	else
		stop
	$("#wait").on 'click', () ->
		stop()
