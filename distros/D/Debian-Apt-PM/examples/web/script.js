var cpan2deb = new Object;

$(document).ready(function() {
	cpan2deb.showInfo();
	$('form').submit(cpan2deb.submitForm);
	$(window).bind('hashchange', cpan2deb.parseParams);
	cpan2deb.parseParams();
	$('input[type="search"]').focus();
});

cpan2deb.showInfo = function () {
	var infoUrl   = 'CPAN/info.json';
	var infoBlock = $('#generatedInfo');
	$.ajax({
		type: "GET",
		url: infoUrl,
		dataType: 'json',
		success: function (data) { infoBlock.text('on '+data.datetime) },
		error: function () { infoBlock.text('no info date-time') },
	});
}

cpan2deb.parseParams = function () {
	var q = $.getURLParam("q");
	
	if (!q) {
		return;
	}
	q = decodeURIComponent(q);

	cpan2deb.module_name(q);
	cpan2deb.submitForm();
}

cpan2deb.module_name = function (new_name) {
	if (new_name) {
		$('input[name="q"]').val(new_name);
	}
	
	// FIXME trim the val() !!!
	var q = $('input[name="q"]').val();
	q = q.replace(/^\s+|\s+$/g, '');
	return q;
}

cpan2deb.submitForm = function () {
	var module_name = cpan2deb.module_name();
	
	var strHref = window.location.href;
	strHref = strHref.replace(/#.+$/, '');
	strHref = strHref.replace(/\?.+$/, '');
	strHref = strHref+'#q='+encodeURIComponent(module_name);
	if (window.location.href != strHref) {
		window.location.href = strHref;
		return false;
	}

	cpan2deb.search(module_name);
	return false;
}

cpan2deb.search = function (q) {
	var md5hex = hex_md5(q).toLowerCase();
	var module_info_file = 'CPAN/'+md5hex.substring(0,2)+'.json';

	$('input[type="submit"]').hide();
	$('.load').show();
	
	$.ajax({ 
		type: "GET",
   		url: module_info_file,
   		dataType: 'json',
		success: function (data) { cpan2deb.show_module_info(q, data); cpan2deb.searchFinish(); },
		error: function () { alert('failed to fetch module information'); cpan2deb.searchFinish(); },
	});
}

cpan2deb.searchFinish = function () {
	$('.load').hide();
	$('input[type="submit"]').show();
	$('input[type="search"]').focus();
}

cpan2deb.show_module_info = function (module_name, module_info) {
	var module_html    = module_name;
	var cpan_path_html = 'n/a';
	var cpan_version   = 'n/a';
	var debs = [];
	
	if (module_info[module_name]) {
		cpan_path_html = '<a href="http://search.cpan.org/CPAN/authors/id/'+module_info[module_name].CPAN.path+'">'+module_info[module_name].CPAN.path+'</a>';
		cpan_version   = module_info[module_name].CPAN.version;
		module_html    = '<a href="http://search.cpan.org/perldoc?'+encodeURIComponent(module_name)+'">'+module_name+'</a>';
		
		if (module_info[module_name].Debian.length == 0) {
			debs = [
				'This module is not packaged for Debian.<br/>'
				+'There are 2 ways to fix this:<br/>'
				+'<ul>'
				+' <li>Use `reportbug wnpp` to <a href="http://pkg-perl.alioth.debian.org/howto/RFP.html">file an RFP</a>.</li>'
				+' <li><a href="http://wiki.debian.org/Teams/DebianPerlGroup/Welcome">Join the Debian Perl Group</a> and help with packaging.</li>'
				+'</ul>'
			];
		}
		else {
			debs = [];
		}
		
		for (i in module_info[module_name].Debian) {
			var deb = module_info[module_name].Debian[i];
			
			debs.push(
				'<div>'
				+'Package: <a href="http://packages.qa.debian.org/'+encodeURIComponent(deb.package)+'">'+deb.package+'</a> [<a href="http://bugs.debian.org/cgi-bin/pkgreport.cgi?pkg='+encodeURIComponent(deb.package)+';dist='+encodeURIComponent(deb.distribution)+'">bugs</a>] [<a href="http://patch-tracker.debian.org/package/'+encodeURIComponent(deb.package)+'/'+encodeURIComponent(deb.version)+'">patches</a>]<br/>'
				+'Package version: '+deb.version+'<br/>'
				+'Module version: '+deb.perl_version+'<br/>'
				+'Arch: '+deb.arch+'<br/>'
				+'Dist: '+deb.distribution+'<br/>'
				+'Component: '+deb.component+'<br/>'
				+'</div>'
			);
		}
	}
	
	$('#cpanModuleName').html(module_html);
	$('#cpanPath').html(cpan_path_html);
	$('#cpanVersion').text(cpan_version);

	$('#debianInfo').html('');
	for (i in debs) {
		var deb = debs[i];
		$('#debianInfo').append(deb+'<br/>');
	}
}

