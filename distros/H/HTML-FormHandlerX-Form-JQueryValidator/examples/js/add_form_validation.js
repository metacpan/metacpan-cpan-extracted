var validationJSON;
$(document).ready(function(){
        validationJSON = JSON.parse(decodeURIComponent($("#validation_json").val() ) );
        $("form.jquery-validate-form").each(function(index) {
                $(this).submit(function(){
                        $(this).validate();
                    });

                $(this).validate({
                        rules: validationJSON.rules,
                            highlight: function(label) {
                            $(label).closest('.control-group').addClass('error');
                        },
                            messages: validationJSON.messages,
                            success: function(label) {
                            label
                                .text('').addClass('valid')
                                .closest('.control-group').addClass('success');
                        }
                    });
            }
            );
    }
); // end document.ready
