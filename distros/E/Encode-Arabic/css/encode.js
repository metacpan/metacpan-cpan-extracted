function encodeYamli (n) {

    var code = document.getElementsByName('decode');

    for (var i = 0; i < code.length; i++) {

        if (code[i].checked) {

            if (code[i].value == 'Unicode') {

                Yamli.yamlify('text');
            }
            else {

                Yamli.deyamlify('text');
            }
        }
    }

    var text = document.getElementById('text');

    text.focus();
    text.select();
}
