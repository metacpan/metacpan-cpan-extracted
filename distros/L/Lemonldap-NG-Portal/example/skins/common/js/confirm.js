/* Timer for confirmation page */

var i = 5;

function go() {
	$("#form").submit();
}

function timer() {
	var h = $('#timer').html();
	if (i > 0) {
		i--;
	}
	h = h.replace(/\d+/, i);
	$('#timer').html(h);
	window.setTimeout('timer()', 1000);
}

$(document).ready(function() {
	window.setTimeout('go()', 5000);
	window.setTimeout('timer()', 1000);
});
