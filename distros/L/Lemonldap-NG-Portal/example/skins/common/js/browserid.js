/* Watch login and logout events */

navigator.id.watch({
	loggedInUser: null,
	onlogin: function(assertion) {
		// POST assertion
		$('form.BrowserID').append('<input type="hidden" name="browserIdAssertion" value="' + assertion + '" />').submit();
	},
	onlogout: function() {
		// Do nothing
	}
});
