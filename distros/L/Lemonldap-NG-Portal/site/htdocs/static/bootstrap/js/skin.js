$(window).on("load", function() {

  // Adapt some class to fit Bootstrap theme
  $("div.message-positive").addClass("alert-success");
  $("div.message-warning").addClass("alert-warning");
  $("div.message-negative").addClass("alert-danger");

  $("table.info").addClass("table");

  $(".notifCheck").addClass("checkbox");

  // Collapse menu on click
  $('.collapse li:not(".dropdown")').on('click', function() {
    if (!$('.navbar-toggler').hasClass('collapsed')) {
      $(".navbar-toggler").trigger("click");
    }
  });

  // Remember selected tab
  $('#authMenu .nav-link').on('click', function (e) {
      window.datas.choicetab = e.target.hash.substr(1)
  });

  // Transmit attributes to remove2f modal
  $('#remove2fModal').on('show.bs.modal', function (event) {
  var button = $(event.relatedTarget) // Button that triggered the modal
  var device = button.attr('device') // Extract device/epoch from button
  var epoch = button.attr('epoch')
  var prefix = button.attr('prefix')
  var modal = $(this)

  // Set device/epoch on modal remove2f button so that the portal JS code can find it
  modal.find('.remove2f').attr('device', device)
  modal.find('.remove2f').attr('epoch', epoch)
  modal.find('.remove2f').attr('prefix', prefix)
})

  // Set tab items (my applications, password, history, logout) tabbable
  // (ie accessible via tab key)
  // needed because of jquery-ui setting only active element tabbable
  // (see #2561)
  $('.nav-item').click(function() {
    $('.nav-item').attr( "tabIndex", 0 );
  });
  $('.nav-item').focusin(function() {
    $('.nav-item').attr( "tabIndex", 0 );
  });
  $('.nav-item').focusout(function() {
    $('.nav-item').attr( "tabIndex", 0 );
  });

  // tick all checkboxes remembering the authentication choice
  // when global checkbox is clicked
  $("#globalrememberauthchoice").change(function() {
      var checked = this.checked;
      $( 'input[name="rememberauthchoice"]' ).each(function() {
          $( this ).val(checked);
      });
  });

  // if rememberStopped button has been clicked, stop the timer
  // from lauching the previously remembered authentication
  $("#buttonRememberStopped").click(function() {
      var curval = $( "input#rememberStopped" ).val();
      var newval;
      if( curval != "stopped" )
      {
          newval = "stopped";
      }
      else
      {
          newval = "running";
          window.setTimeout( launchAuthenticationChoice, 0 );
      }
      // store the new value
      $( "input#rememberStopped" ).val(newval);
      $( "#remembertimercontainer" ).hide();
      $( "#globalrememberauthchoicecontainer" ).css('display', 'flex');
  });

  // function running the previously remembered authentication choice
  // when the timer is over
  function launchAuthenticationChoice()
  {

      var timer = $( "span#remembertimer" ).text();
      var isStopped = $( "input#rememberStopped" ).val();

      if ( isStopped != "stopped" )
      {
          timer--;
          // display decremented timer in the appropriate html element
          $( "span#remembertimer" ).text(timer);

          if ( timer > 0 )
          {
              // wait for another 1s
              window.setTimeout( launchAuthenticationChoice, 1000 );
          }
          else
          {
              // launch authentication choice defined in cookie
              var choiceform = "#" + $.cookie(rememberCookieName) + " form";
              $( choiceform ).submit();
          }
      }

  };


  // Check rememberauthchoice cookie
  var rememberCookieName = $( "#rememberCookieName" ).val();
  var errorCode = $( "#errormsg div span" ).attr("trmsg");
  // if this is first access
  if( errorCode == 9 )
  {
      // if there is a rememberauthchoice cookie
      if (  ! ( typeof rememberCookieName === 'undefined' ) &&
            ! ( typeof $.cookie(rememberCookieName) === 'undefined' )
         )
      {
          // show timer
          $( "#remembertimercontainer" ).css('display', 'flex');
          // remember last authentication choice again
          $("#globalrememberauthchoice").prop('checked',true);
          $( 'input[name="rememberauthchoice"]' ).each(function() {
            $( this ).val('true');
          });
          // increment timer for starting to correct time
          $( "span#remembertimer" ).text( parseInt($( "span#remembertimer" ).text()) + 1 );
          // launch remembered authentication choice when timer reaches 0
          window.setTimeout( launchAuthenticationChoice, 0 );
      }
      else
      {
        // display the global checkbox
        $( "#globalrememberauthchoicecontainer" ).css('display', 'flex');
      }
  }

});
