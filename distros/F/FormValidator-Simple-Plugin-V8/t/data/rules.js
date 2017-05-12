
rule("NUMBER", function (str) {
	str = String(str);
	return (/^\d+$/).test(str);
});

rule("STR_MAX", function (str, len) {
	return String(str).length <= len;
});

