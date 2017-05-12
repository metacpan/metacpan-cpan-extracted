/**
 * LemonLDAP::NG Portal jQuery scripts
 */

/* Used variables
 * - displaytab
 * - choicetab
 * - autocomplete
 * - login
 * - newwindow
 * - antiframe
 */

/* Set autocomplete real value */
if (autocomplete.match('1')) {
	autocomplete = 'on';
}
if (autocomplete.match('0')) {
	autocomplete = 'off';
}

/* Set newwindow value (default is false) */
if (newwindow.match('1')) {
	newwindow = true;
} else {
	newwindow = false;
}

/* Set antiframe value (default is true) */
if (antiframe.match('0')) {
	antiframe = false;
} else {
	antiframe = true;
}

/* Set activeTimer value (default is true) */
if (activeTimer.match('0')) {
	activeTimer = false;
} else {
	activeTimer = true;
}

/* jQuery */
$(document).ready(function() {

	/* AntiFrame script */
	if (antiframe && top != self) {
		top.location.href = location.href;
	}

	/* Sortable menu */
	$("#appslist").sortable({
		axis: "y",
		cursor: "move",
		opacity: 0.5,
		revert: true,
		items: "> div.category",
		update: function() {
			getOrder();
		}
	});

	restoreOrder();

	/* Display message */
	$("div.message").fadeIn('slow');

	/* Set timezone */
	$("input[name=timezone]").val(-(new Date().getTimezoneOffset() / 60));

	/* Menu tabs */
	var menuTabs = $("#menu").tabs({
		active: 0
	});
	var menuIndex = $('#menu a[href="#' + displaytab + '"]').parent().index();
	if (menuIndex < 0) {
		menuIndex = 0;
	}
	menuTabs.tabs("option", "active", menuIndex);

	/* Authentication choice tabs */
	var authMenuTabs = $("#authMenu").tabs({
		active: 0
	});
	// TODO: cookie
	//$("#authMenu").tabs({cookie: {name: 'lemonldapauthchoice'}});
	if (choicetab) {
		var authMenuIndex = $('#authMenu a[href="#' + choicetab + '"]').parent().index();
		authMenuTabs.tabs("option", "active", authMenuIndex);
	}

	/* Focus on first visible input */
	$("input[type!=hidden]:first").focus();
	if (login) {
		$("input[type=password]:first").focus();
	}

	/* Password autocompletion */
	$("input[type='password']").attr("autocomplete", autocomplete);

	/* Open links in new windows */
	if (newwindow) {
		$('#appslist a').attr("target", "_blank");
	}

	/* Complete removeOther link */
	if ($("p.removeOther").length) {
		var action = $("form.login").attr("action");
		var method = $("form.login").attr("method");

		var back_url = "";
		if (action.indexOf("?") != -1) {
			back_url = action.substring(0, action.indexOf("?")) + "?";
		} else {
			back_url = action + "?";
		}

		$("form.login input[type=hidden]").each(function(index) {
			back_url = back_url + "&" + $(this).attr("name") + "=" + $(this).val();
		});

		var link = $("p.removeOther a").attr("href");

		link = link + "&method=" + method + "&url=" + $.base64Encode(back_url);

		$("p.removeOther a").attr("href", link);

	}
});

/* Code from http://snipplr.com/view/29434/ */
// set the list selector
var setSelector = "#appslist";
// function that writes the list order to session
function getOrder() {
	// save custom order to persistent session
	$.ajax({
		type: "POST",
		url: scriptname,
		data: {
			storeAppsListOrder: $(setSelector).sortable("toArray").join()
		},
		dataType: 'json'
	});
}

// function that restores the list order from session
function restoreOrder() {
	var list = $(setSelector);
	if (list == null) return;

	// fetch the session value (saved order)
	if (!appslistorder) return;

	// make array from saved order
	var IDs = appslistorder.split(",");

	// fetch current order
	var items = list.sortable("toArray");

	// make array from current order
	var rebuild = new Array();
	for (var v = 0, len = items.length; v < len; v++) {
		rebuild[items[v]] = items[v];
	}

	for (var i = 0, n = IDs.length; i < n; i++) {

		// item id from saved order
		var itemID = IDs[i];

		if (itemID in rebuild) {

			// select item id from current order
			var item = rebuild[itemID];

			// select the item according to current order
			var child = $(setSelector + ".ui-sortable").children("#" + item);

			// select the item according to the saved order
			var savedOrd = $(setSelector + ".ui-sortable").children("#" + itemID);

			// remove all the items
			child.remove();

			// add the items in turn according to saved order
			// we need to filter here since the "ui-sortable"
			// class is applied to all ul elements and we
			// only want the very first! You can modify this
			// to support multiple lists - not tested!
			$(setSelector + ".ui-sortable").filter(":first").append(savedOrd);
		}
	}
}

/* function boolean isHiddenFormValueSet(string option)
 * Check if an hidden option is set
 * @param option Option name
 * @return true if option is set, false else
 */
function isHiddenFormValueSet(option) {
	if ($('#lmhidden_' + option).length) {
		return true;
	} else {
		return false;
	}
}

/* function void ping()
 * Check if session is alive on server side
 * @return nothing
 */
function ping() {
	$.ajax({
		type: "POST",
		url: scriptname,
		data: {
			ping: 1
		},
		dataType: 'json',
		success: function(data) {
			if (!data.auth) {
				location.reload(true);
			}
			else {
				setTimeout('ping();', pingInterval);
			}
		}
	});
}
