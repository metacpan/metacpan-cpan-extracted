###
LemonLDAP::NG Notifications script
###

msg = $('#msg').attr 'trspan'

setMsg = (msg, level) ->
	$('#msg').html window.translate msg
	$('#color').removeClass 'message-positive message-warning alert-success alert-warning'
	$('#color').addClass "message-#{level}"
	level = 'success' if level == 'positive'
	$('#color').addClass "alert-#{level}"
	$('#color').attr "role", "status"

displayError = (j, status, err) ->
	setMsg 'notificationRetrieveFailed', 'warning'
	console.log 'Error:', err, 'Status:', status

toggle_eye = (slash) ->
		if slash
			$("#icon-explorer-button").removeClass 'fa-eye'
			$("#icon-explorer-button").addClass 'fa-eye-slash'
		else
			$("#icon-explorer-button").removeClass 'fa-eye-slash'
			$("#icon-explorer-button").addClass 'fa-eye'

toggle_explorer = (visible) ->
		if visible
			$('#explorer').hide()
			$('#color').hide()
			toggle_eye 0
		else
			$('#explorer').show()
			$('#color').show()
			toggle_eye 1

toggle = (button, notif, epoch) ->
		setMsg msg, 'positive'
		$(".btn-danger").each ->
			$(this).removeClass 'btn-danger'
			$(this).addClass 'btn-success'
		$(".fa-eye-slash").each ->
			$(this).removeClass 'fa-eye-slash'
			$(this).addClass 'fa-eye'
		$(".verify").each ->
			$(this).text window.translate 'verify'
			$(this).attr('trspan', 'verify')
		if notif and epoch
			button.removeClass 'btn-success'
			button.addClass 'btn-danger'
			$("#icon-#{notif}-#{epoch}").removeClass 'fa-eye'
			$("#icon-#{notif}-#{epoch}").addClass 'fa-eye-slash'
			$("#text-#{notif}-#{epoch}").text window.translate 'hide'
			$("#text-#{notif}-#{epoch}").attr('trspan', 'hide')
			$("#myNotification").removeAttr('hidden')
			toggle_eye 1
		else
			$("#myNotification").attr('hidden', 'true')
			$("#explorer-button").attr('hidden', 'true')

# viewNotif function (launched by "verify" button)
viewNotif = (notif, epoch, button) ->
		console.log 'Ref:', notif, 'epoch:', epoch
		if notif and epoch
			console.log 'Send AJAX request'
			$.ajax
				type: "GET"
				url: "#{portal}mynotifications/#{notif}"
				data:
					epoch: epoch
				dataType: 'json'
				error: displayError
				success: (resp) ->
					if resp.result
						console.log 'Notification:', resp.notification
						toggle button, notif, epoch
						$('#displayNotif').html resp.notification
						$('#notifRef').text(notif)
						myDate = new Date(epoch * 1000)
						$('#notifEpoch').text(myDate.toLocaleString())
						$("#explorer-button").removeAttr('hidden')
					else setMsg 'notificationNotFound', 'warning'
		else setMsg 'notificationRetrieveFailed', 'warning'

# Register "click" events
$(document).ready ->
	$(".data-epoch").each ->
		myDate = new Date($(this).text() * 1000)
		$(this).text(myDate.toLocaleString())
	$('#goback').attr 'href', portal
	$('body').on 'click', '.btn-success', () -> viewNotif ( $(this).attr 'notif' ), ( $(this).attr 'epoch' ), $(this)
	$('body').on 'click', '.btn-danger', () -> toggle $(this)
	$('body').on 'click', '.btn-info', () -> toggle_explorer $('#explorer').is(':visible')
