$(document).ready(function(){
	$("a.ajax").click(function(){
		var link = this;
		var href = $(link).attr("href");

		$(link).attr("href","#");

		$.getJSON(href,function(json){
			$(link).attr("href",href);
			if(json.headline){
				$("#headline").html(json.headline);
			}
			else{
				$("#headline").text("Error");
			}
			if(json.dyncontent){
				$("#dyncontent").html(json.dyncontent);
			}
			else{
				$("#dyncontent").text("Error");
			}
			if(json.permalink){
				$("#permalink").html(json.permalink);
			}
			else{
				$("#permalink").text("Error");
			}
		})
	});
});

