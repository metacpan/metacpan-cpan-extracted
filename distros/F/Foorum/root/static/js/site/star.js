function star(obj_type, obj_id, obj_div) {
    $.get('/ajax/star', { 'obj_type': obj_type, 'obj_id': obj_id }, function(data) {
        if (data == 1) {
            $('#' + obj_div).html('<img src="/static/images/site/t/star_on.gif" />');
        } else {
            $('#' + obj_div).html('<img src="/static/images/site/t/star_off.gif" />');
        }
    } );
}

function share(obj_type, obj_id, obj_div) {
    $.get('/ajax/share', { 'obj_type': obj_type, 'obj_id': obj_id }, function(data) {
        if (data == 1) {
            $('#' + obj_div).html('<img src="/static/images/site/t/unshare.gif" />');
        } else {
            $('#' + obj_div).html('<img src="/static/images/site/t/share.gif" />');
        }
    } );
}