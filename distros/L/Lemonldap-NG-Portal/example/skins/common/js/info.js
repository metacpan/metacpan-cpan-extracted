/* Timer for information page */

var i = 10;
var _go = 1;

function stop() {
	_go = 0;
	$('#timer').html("...");
}

function go() {
	if (_go) {
		$("#form").submit();
	}
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
	if (activeTimer) {
		window.setTimeout('go()', 10000);
		window.setTimeout('timer()', 1000);
	} else {
		stop();
	}
});
