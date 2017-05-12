function confirmDelete() {
    var agree = confirm("This cannot be undone. Are you sure?");
    if (agree) return true
    else return false;
}

/* If an ajax event updates another dom object which is being observed,
  there is no event that fires to let the observer know. This function allows
  us to explicitly (manually) fire an event, so that the observed action
  takes place. */
function fireEvent(element,event){
    if(document.createEvent){
        // dispatch for firefox + others
        var evt = document.createEvent("HTMLEvents");
        evt.initEvent(event, true, true ); // event type,bubbling,cancelable
        return !element.dispatchEvent(evt);
    }
    else{
        // dispatch for IE
        var evt = document.createEventObject();
        return element.fireEvent('on'+event,evt);
    }
}