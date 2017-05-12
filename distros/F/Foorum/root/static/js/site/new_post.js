function switch_formatter() {
    var selected_format = $('input[@name=formatter]:checked').val();
    if (selected_format == 'ubb') {
        $('.ubb').show();
        $('.wiki').hide();
    } else if (selected_format == 'wiki') {
        $('.ubb').hide();
        $('.wiki').show();
    } else {
        $('.ubb').hide();
        $('.wiki').hide();
    }
}

function preview() {
    var formatter = $('input[@name=formatter]:checked').val();
    var ctext = $('#text').val();
    
    $.post('/ajax/preview', { 'formatter': formatter, 'text': ctext }, function(data) {
        $('#preview').html(data);
    } );
}

$(document).ready(function() {
    switch_formatter();
} );