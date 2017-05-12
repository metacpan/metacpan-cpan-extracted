$(document).ready(function() {

	// Manage auto login
	if (browserIdAutoLogin.match('1')) {
		launchRequest();
	}

	// Intercept submit the first time
	var intercepted = 0;
	$("form.BrowserID").submit(function(event) {
		if (!intercepted) {
			event.preventDefault();
			intercepted = 1;
			launchRequest();
		}
	});

});

function launchRequest() {
	navigator.id.request({
		siteName: browserIdSiteName,
		siteLogo: browserIdSiteLogo,
		backgroundColor: browserIdBackgroundColor
	});
}
