//# sourceMappingURL=collaboration-all.js.map
var olefa_sync = function() {
	this.default_values();
};

olefa_sync.prototype.default_values = function() {
	this.timer = setInterval((function(self) {
		return function() {self.execute();}
	})(this), 45000);
	this.active = new Object();
	this.unixTimestamp = Math.round(+new Date()/1000);
	this.xhr = null;
};

olefa_sync.prototype.execute = function(val) {
	if (this.xhr && typeof(this.xhr.abort) == 'function') {
		this.xhr.abort();
	}	
	
	var pData = new Object();
	var size = 0;
	for (var key in this.active) {
		this.active[key].beforeSend();
		pData[key] = this.active[key].data;
		++size;
	};
	
	if (size > 0) {
		//the weird function definition is necessary to preserve "this" as a reference to itself in object notation
		this.xhr = jQuery.ajax({
			url: '/ajax/sync',
			dataType: 'json',
			type: 'POST',
			data: {
				com: com,
				mode: 'sync',
				last_sync: this.unixTimestamp,
				data: JSON.stringify(pData)
			},
			beforeSend: (function(self) {
				return function(json) {
					//for (var key in self.active) {
					//	self.active[key].beforeSend();
					//}
				}
			})(this),
			success: (function(self) {
				return function(json) {self.onExecuteSuccess(json)}
			})(this),
			error: (function(self) {
				return function(XHR, textStatus, errorThrown) {
					for (var key in self.active) {
						self.active[key].onError(XHR, textStatus, errorThrown);
					}
				}
			})(this)
		});
	}
	
	this.unixTimestamp = Math.round(+new Date()/1000);
};

olefa_sync.prototype.onExecuteSuccess = function(json) {
	for (var key in json) {
		if (this.active[key]) {
			this.active[key].onSuccess(json[key]);
		}
	}
};

olefa_sync.prototype.addJob = function(key, properties) {
	if (typeof(key) != 'string') {
		return false;
	}
	if (typeof(properties.data) != 'object') {
		return false;
	}
	if (typeof(properties.onSuccess) != 'function') {
		return false;
	}
	if (typeof(properties.onError) != 'function') {
		return false;
	}
	if (typeof(properties.beforeSend) != 'function') {
		properties.beforeSend = function() {};
	}
	
	var job = new olefa_sync_object();
	job.data = properties.data;
	job.onSuccess = properties.onSuccess;
	job.onError = properties.onError;
	job.beforeSend = properties.beforeSend;
	this.active[key] = job;
};

olefa_sync.prototype.removeJob = function(key) {
	if (this.active[key]) {
		delete this.active[key];
	}
};

//////////////////////////////////////////////////////////////////////////
var olefa_sync_object = function() {
	this.default_values();
};

olefa_sync_object.prototype.default_values = function() {
	this.onSuccess = function() {};
	this.data = {};
	this.onError = function() {};
	this.beforeSend = function() {};
};
if (typeof(Core) == 'undefined') {
	Core = new Object();
};

Core.sync = new olefa_sync();

var twoHoursInMilliseconds = 720000;

OLEFA.registerModule('collaboration', function(resolve, reject) {
	var collaboration = Core.collaboration;

	jQuery(document).on('click', '.subscribetoproject', function(){
		var li = jQuery(this); 
		jQuery.ajax('/ajax/sync', {
			type: 'POST',
			dataType: 'json',
			data: {
				mode: 'subscribe',
				projectid: Core[app].projectid
			},
			beforeSend: function() {
				li.css('opacity', 0.5);
			},
			success: function(json) {
				if (json.status == 1) {
					li.replaceWith('<li style="padding-top: 3px; padding-bottom: 3px;" class="unsubscribefromproject"><img alt="icon" src="/osr/icons/flat/bw/24/unsubscribeemail.png"><span style="">'+OLEFA.i18n.get('unsubscribefromproject')+'</span></li>');
				}
			},
			error: function() {
				li.css('opacity', 1);
			}
		});
	});
	
	jQuery(document).on('click', '.unsubscribefromproject',function(){
		var li = jQuery(this); 
		jQuery.ajax('/ajax/sync', {
			type: 'POST',
			dataType: 'json',
			data: {
				mode: 'unsubscribe',
				projectid: Core[app].projectid
			},
			beforeSend: function() {
				li.css('opacity', 0.5);
			},
			success: function(json) {
				if (json.status == 1) {
					li.replaceWith('<li style="padding-top: 3px; padding-bottom: 3px;" class="subscribefromproject"><img alt="icon" src="/osr/icons/flat/bw/24/subscribeemail.png"><span style="">'+OLEFA.i18n.get('subscribetoproject')+'</span></li>');
				}
			},
			error: function() {
				li.css('opacity', 1);
			}
		});
	});
	
	jQuery(".sf-olefatoolbar, .sf-res-olefatoolbar").superfish({
		autoArrows	:false,
		delay: 500,
		onBeforeShow: function() {
			var jParent = jQuery(this).parent();
			if (!jParent.parent().hasClass('sf-olefatoolbar')) {
				var position = jParent.position();
				if (typeof(position) != 'undefined') {
					jQuery(this).css({
						'top': position.top
					});
				}
			}
		}
	});

	//stuff for link generation, rewritten in proper unobstrusive JS
	//If I ever see a <script> tag in the <body>-tag again I will kick you in the BALLS!
	jQuery(document).on('click','.internal_value',function(){
		jQuery('.internal_value').select();
	});
	jQuery(document).on('click','.external_value',function(){
		jQuery('.external_value').select();
	});
	
	jQuery(document).on('click','#menuitem_Link', function() {
		linkShare();
	});
	
	jQuery(document)
		.on('change', 'input#userhome-main-controls-post-details-share-panel-general-everyone:checked', function() {onNewPostShareChange(0)})
		.on('change', 'input#userhome-main-controls-post-details-share-panel-general-specific:checked', function() {onNewPostShareChange(1)})
		.on('change', 'input.userhome-main-controls-post-details-share-panel-checkbox', function() {onNewPostShareGroupChange(this)})
		.on('change', 'select.userhome-main-controls-post-details-share-panel-accesslevel', function() {onNewPostShareGroupChangeSelect(this)});

	jQuery(document)
		.on('click','#menuitem_Pin', function() {
			jQuery.ajax('/ajax/userhome', {
				type: 'POST',
				dataType: 'json',
				data: {
					com: com,
					mode: 'getProjectSharePanel',
					module: jQuery(this).data('module'),
					projectid: jQuery(this).data('projectid'),
					pageid: jQuery(this).data('pageid')
				},
				success: function(json) {
					showSharePanel(json);
				}
			});
		})
		.on('click','#menuitem_Base', function() {
			jQuery.ajax('/ajax/userhome', {
				type: 'POST',
				dataType: 'json',
				data: {
					com: com,
					mode: 'getBaseSharePanel',
					projectid: jQuery(this).data('projectid'),
					pageid: jQuery(this).data('pageid')
				},
				success: function(json) {
					showBaseSharePanel(json);
				}
			});
		});
	
	if (Core.status.valid_login) {
		var timestamp = jQuery('span.menuitem-notification-timestamp:first').text();
		jQuery(document).on('olefa-notification', function(e, payload) {
			onNotification_collaboration(payload);
		});
	}
	
	jQuery('ul.sf-olefatoolbar').on('click', 'span.menuitem-notification-delete', function(event) {
		var jCaller = jQuery(this);
		var id = jCaller.data('id');
		jQuery.ajax('/ajax/userhome', {
			type: 'POST',
			dataType: 'json',
			data: {
				com: com,
				mode: 'delete_notification',
				id: id
			},
			beforeSend: function() {
				jCaller.parent().css('opacity', 0.5);
			},
			success: function() {
				jCaller.parent().remove();
			},
			error: function() {
				jCaller.parent().css('opacity', 1);
			}
		});
		event.stopPropagation();
	});
	
	jQuery('ul.sf-olefatoolbar').on('click', 'li.conversation', function() {
		var jCaller = jQuery(this);
		var id = jCaller.data('id');
		jQuery.ajax('/ajax/conversation', {
			type: 'POST',
			dataType: 'html',
			data: {
				com: com,
				mode: 'list_last_messages',
			},
			success: function(html) {
				jCaller.children('ul').remove();
				jCaller.append(html);
			}
		});
	});
	
	jQuery('ul.sf-olefatoolbar').on('click', 'li.unread-messages-item', function() {
		var jCaller = jQuery(this);
		var id = jCaller.data('conversationid');
		//window.open('/conversation?com='+com+'&convo='+id);
		if (typeof(Core.minichat.conversations[id]) == 'undefined') {
			Core.minichat.handleMessage({conversation: id}, true);
		};
	});
	
	 jQuery(document).on('click', 'li.notification_item', function() {
		 var link = jQuery(this).attr('data-link');
		 if (link) {
			 window.location = link;
		 };
	 });

	 return resolve();
});

function linkShare(module) {
	var dialog_content = '<table class="link-table"><tr><td colspan="3">'+OLEFA.i18n.get('linkDescription')+'</td></tr>' +
		'<tr><td><strong>'+OLEFA.i18n.get('internalLink')+'</strong></td>'+
			'<td><input class="copy_value internal_value" type="text" value="[['+Core.shareData.internalLink+']]" style="width:320px"></td>'+
			'<td><div id="copy_1" class="copypaste" style="position:relative;"><button value="Copy" class="flash_copy" id="button_1">'+OLEFA.i18n.get('copy')+'</button></div></td>' +
		'</tr><tr><td><strong>'+OLEFA.i18n.get('externalLink')+'</strong></td>'+
			'<td><input class="copy_value external_value" type="text" value="'+Core.shareData.externalLink+'" style="width:320px"></td>' +
			'<td><div id="copy_2" class="copypaste" style="position:relative;"><button value="Copy" class="flash_copy" id="button_2">'+OLEFA.i18n.get('copy')+'</button></div></td>' +
		'</tr><tr><td><strong>'+OLEFA.i18n.get('qrCodeLink')+'</strong></td><td><div class="qr_code_share"></div></td></tr>';
		
	if(typeof(module) != 'undefined' && module == 'storyboard') {
		dialog_content +='<tr><td><strong>'+OLEFA.i18n.get('slideshowLink')+'</strong></td>'+
		'<td><input class="copy_value slideshow_value" type="text" value="'+Core.shareData.slideshowLink+'" style="width:320px"></td>'+
		'<td><div id="copy_3" class="copypaste" style="position:relative;"><button "value="Copy" class="flash_copy" id="button_3">'+OLEFA.i18n.get('copy')+'</button></div></td><tr>';
	};

	dialog_content +='</table>';
	
	dialogheader({
		id: 'link-share',
		title: OLEFA.i18n.get('copy_to_clipboard'),
		content: dialog_content,
		simpleClose: true
	}).then(function(jDialog) {
		jDialog.appendTo('body').trigger('show');
		createOlefaButtons();
		init_copypaste();
		init_qrcode_share();
	});
};

function onNotification_collaboration(message) {
	var now = Date.now();
	if (message.action == 'new') {
		var displayNotification = true;
		if (message.data.activation) {
			var isodatestr = message.data.activation.replace(' ', 'T');
			var date = new Date(isodatestr).getTime();
			if (now < date) {
				OLEFA.crontab.addJob({
					id: 'notification-'+message.data.id,
					at: isodatestr,
					instances: 1,
					persistent: true,
					onTick: 'onNotification_collaboration',
					onTickParams: [message]
				});
				displayNotification = false;
			}
		};
		if (displayNotification) {
			OLEFA.templateEngine.getTemplate('Notifications/Notification-Item.html')
				.then(function(template) {
					var jTemplate = jQuery(template);
					jTemplate.find('img.menuitem-notification-image').prop('src', message.data.icon_large);
					jTemplate.addClass('new');
					jTemplate.attr('data-link', message.data.link);
					template = jTemplate.get(0).outerHTML;
					var text = message.data.text[Core.status.sitelang] || message.data.text.en;
					var html = OLEFA.templateEngine.render(template, {
						LABEL: text.text,
						TIMESTAMP: message.data.last_update,
						ID: message.data.id
					});
					var jNotifications = jQuery('ul.sf-olefatoolbar>li.notification');
					jNotifications.addClass('new');
					jNotifications.children('ul').prepend(html);
					var count = jNotifications.children('span').text();
					jNotifications.children('span').text(++count);
					/*
					OLEFA.notifications.createNotification({
						id: message.data.id,
						title: text.title,
						message: text.text,
						link: message.data.link,
						icon: message.data.from.photo
					});
					*/
				
					OLEFA.notifications.createNotification({
						tag: 'notification-'+message.data.id,
						title: text.title,
						body: text.text,
						icon: message.data.from.photo,
						onClick: function() {
							window.location.href = message.data.link;
						}
					});
				});			
		};			
	} else if (message.action == 'update') {
		var displayNotification = true;
		if (message.data.activation) {
			var isodatestr = message.data.activation.replace(' ', 'T');
			var date = new Date(isodatestr).getTime();
			if (now < date) {
				OLEFA.crontab.addJob({
					id: 'notification-'+message.data.id,
					at: isodatestr,
					instances: 1,
					persistent: true,
					onTick: 'onNotification_collaboration',
					onTickParams: [message]
				});
				displayNotification = false;
			}
		};
		if (displayNotification) {
			var jNotification = jQuery('li.notification_item[data-id="'+message.data.id+'"]');
			jNotification.find('span.menuitem-notification-timestamp')
				.text(message.data.last_update);
			var jNotifications = jQuery('ul.sf-olefatoolbar>li.notification');
			if (!jNotification.hasClass('new')) {
				jNotification
					.addClass('new');
				jNotifications.addClass('new');
				var count = jNotifications.children('span').text();
				jNotifications.children('span').text(++count);
			}
			var text = message.data.text[Core.status.sitelang] || message.data.text.en;
			jNotification.find('p.menuitem-notification-label')
				.text(text.text);
			/*
			OLEFA.notifications.createNotification({
				id: message.data.id,
				title: text.title,
				message: text.text,
				link: message.data.link,
				icon: message.data.from.photo
			});
			*/
			OLEFA.notifications.createNotification({
				tag: 'notification-'+message.data.id,
				title: text.title,
				body: text.text,
				icon: message.data.from.photo,
				onClick: function() {
					window.location.href = message.data.link;
				}
			});
		}
	} else if (message.action == 'read') {
		var jNotification = jQuery('li.notification_item[data-id="'+message.data.id+'"]');
		var jNotifications = jQuery('ul.sf-olefatoolbar>li.notification');
		if (jNotification.hasClass('new')) {
			jNotification
				.removeClass('new');
			var count = jNotifications.children('span').text();
			jNotifications.children('span').text(--count);
			if (count <= 0) {
				jNotifications.removeClass('new');
			}
		}
	} else if (message.action == 'delete') {
		var jNotification = jQuery('li.notification_item[data-id="'+message.data.id+'"]');
		if (jNotification.hasClass('new')) {
			var jNotifications = jQuery('ul.sf-olefatoolbar>li.notification');
			var count = jNotifications.children('span').text();
			jNotifications.children('span').text(--count);
			if (count <= 0) {
				jNotifications.removeClass('new');
			};
		}
		jNotification.remove();
	};
};

function showSharePanel(pinIt) {
	var dialog_content = '<textarea id="share_text">[['+pinIt.share_link+']]</textarea>' +pinIt.share_panel;
	var Button = {};
	Button[pinIt.lang.cancel] = function() {
		jQuery(this).dialog('close');
	};
	Button[pinIt.lang.send] = function(){
		onPostSendClick(this);
	};
	dialog(pinIt.lang.share_to_pinboard, dialog_content, 6).prop('id', 'share_to_pinboard').dialog ({
		buttons: Button,
		width: 600,
		modal: true
	});
	var groups = pinIt.share_settings.groups;
	if (pinIt.share_settings.global == 'everyone') {
		jQuery('input#userhome-main-controls-post-details-share-panel-general-everyone').trigger('click');
	} else {
		jQuery('input#userhome-main-controls-post-details-share-panel-general-specific').trigger('click');
	};
	for (var i = 0; i < groups.length; ++i) {
		var group = groups[i];
		jQuery(document).find('input.userhome-main-controls-post-details-share-panel-checkbox[data-id="'+group.id+'"]').trigger('click');
		jQuery(document).find('select.userhome-main-controls-post-details-share-panel-accesslevel[data-groupid="'+group.id+'"]').val(group.accesslevel);
	};
};

function showBaseSharePanel(baseit) {
	var dialog_content = '<label for="share_title">'+baseit.lang.share_title+'</label><input id="share_title" name="share_title" value="'+baseit.share_title+'">' +baseit.share_panel;
	var Button = {};
	Button[baseit.lang.cancel] = function() {
		jQuery(this).dialog('close');
	};
	Button[baseit.lang.send] = function(){
		onBaseSendClick(this);
	};
	dialog(baseit.lang.share_to_base, dialog_content, 6).prop('id', 'share_to_base').dialog ({
		buttons: Button,
		width: 600,
		modal: true
	});
};

function onNewPostShareChange(setting) {
	if (setting == 0) {
		jQuery('#share_to_pinboard')
			.find('div#userhome-main-controls-post-details-share-panel table.grouplist :input')
				.prop('disabled', 'disabled');
	} else {
		jQuery('#share_to_pinboard')
			.find('div#userhome-main-controls-post-details-share-panel table.grouplist :input')
				.removeProp('disabled');
		jQuery('#share_to_pinboard')
			.find('div#userhome-main-controls-post-details-share-panel table.grouplist input.userhome-main-controls-post-details-share-panel-checkbox:checked')
				.each(function() {
					onNewPostShareGroupChange(this);
				});
	};
};

function onNewPostShareGroupChangeSelect(caller) {
	var jInput = jQuery(caller)
		.parents('tr:first')
		.find('input.userhome-main-controls-post-details-share-panel-checkbox');
	onNewPostShareGroupChange(jInput.get(0));
};

function onNewPostShareGroupChange(caller) {
	var checked = (jQuery(caller).is(':checked')) ? true : false;
	var jTr = jQuery(caller).parents('tr:first');
	var indent = jTr.data('indent');
	var jNext = jTr.next('tr');
	while (jNext.data('indent') > indent) {
		var jInput = jNext.find('input.userhome-main-controls-post-details-share-panel-checkbox, select');
		if (checked) {
			jInput.prop('disabled', 'disabled').prop('checked', 'checked');
		} else {
			jInput.removeProp('disabled').removeProp('checked');
		};
		jNext = jNext.next('tr');
	};
};

function onPostSendClick(caller) {
	var text = jQuery('textarea#share_text').val();
	if (text == '') {return false};
	
	var shareSettings = {
			groups: [],
			global: jQuery('input[name="share_everybody"]:checked').val()
	};
	jQuery('input.userhome-main-controls-post-details-share-panel-checkbox:checked').not(':disabled').each(function() {
		var jThis = jQuery(this);
		var id = jThis.data('id');
		var accesslevel = jThis.parents('tr:first').find('select.userhome-main-controls-post-details-share-panel-accesslevel').val();
		shareSettings.groups.push({
			id: id,
			accesslevel: accesslevel
		});
	});
	
	jQuery.ajax('/ajax/userhome', {
		type: 'POST',
		dataType: 'json',
		data: {
			mode: 'share-post',
			settings: JSON.stringify(shareSettings),
			text: text
		},
		beforeSend: function() {
			jQuery('div#share_to_pinboard').css('opacity', 0.5);
		},
		success: function(json) {
			if (json.status == 0) {
				jQuery(caller).dialog('close');
			} else {
				simple_dialog('Error', 'Error');
			};
		},
		complete: function() {
			jQuery('div#share_to_pinboard').css('opacity', 1);
		}
	});
};

function onBaseSendClick(caller) {
	var title = jQuery('input#share_title').val();
	var base = jQuery('select#base-share-select').val();
	var projectid = jQuery('input#share_projectid').val();
	var pageid = jQuery('input#share_pageid').val();
	if (title == '') {return false};
	if (base == '') {return false};
	if (projectid == '') {return false};
	
	jQuery.ajax('/ajax/olefabase', {
		type: 'POST',
		dataType: 'json',
		data: {
			com: com,
			mode: 'shareProject',
			base: base,
			projectid: projectid,
			pageid: pageid,
			title: title
		},
		beforeSend: function() {
			jQuery('div#share_to_base').css('opacity', 0.5);
		},
		success: function(json) {
			if (json.status == 0) {
				jQuery(caller).dialog('close');
				window.location = json.redirect;
			} else {
				simple_dialog(json.title, json.text, 6);
			};
		},
		complete: function() {
			jQuery('div#share_to_base').css('opacity', 1);
		}
	});
};

function init_copypaste(){
	jQuery(document).on('click', 'table.link-table div.copypaste button', function() {
		var jValue = jQuery(this).parents('tr:first').find('input.copy_value');
		jValue.get(0).select();
		try {
			var successful = document.execCommand('copy');
			if (!successful) {
				console.log('Copy failed');
			}
		} catch (err) {
			console.log('Copy failed');
		};
	});
};

function init_qrcode_share() {
	var qrcodeDiv = document.getElementsByClassName('qr_code_share')[0];
	qrcode = new QRCode(qrcodeDiv, {width : 100,height : 100,correctLevel: QRCode.CorrectLevel.L});
	qrcode.makeCode(Core.shareData.externalLink);
};

function imageZoom() {
	var jThis = jQuery(this);
	var jClone = jThis.clone();
	jQuery('body').append('<div id="conversation-blur"></div>');
	jClone.appendTo('body');
	jClone.css({
		'position': 'fixed',
		'left': jThis.offset().left - jQuery(document).scrollLeft(),
		'top': jThis.offset().top - jQuery(document).scrollTop(),
		'max-width': jThis.width(),
		'max-height': jThis.height(),
		'min-width': jThis.width(),
		'min-height': jThis.height(),
		'width': '100%',
		'height': '100%',
		'z-index': '101'
	});
	
	var maxWidth = Math.min(document.documentElement.clientWidth, jThis.get(0).naturalWidth);
	var maxHeight = Math.min(document.documentElement.clientHeight, jThis.get(0).naturalHeight);
	var heightOffset = (document.documentElement.clientHeight > jThis.get(0).naturalHeight)
		? (document.documentElement.clientHeight - jThis.get(0).naturalHeight) / 2
		: 0;
	var widthOffset = (document.documentElement.clientWidth > jThis.get(0).naturalWidth)
		? (document.documentElement.clientWidth - jThis.get(0).naturalWidth) / 2
		: 0;
	if (jThis.width()/jThis.height() >= 1) {
		var ratio = maxWidth / jThis.width();
		var top = (maxHeight - jThis.height() * ratio) / 2 + heightOffset;
		
		jClone.css({
			'height': 'auto'
		});
		jClone.animate({
			'left': widthOffset,
			'top': top,
			'max-width': maxWidth,
			'max-height': maxHeight
		});				
	} else {
		var ratio = maxHeight / jThis.height();
		var left = (maxWidth - jThis.width() * ratio) / 2 + widthOffset;
		jClone.css({
			'width': 'auto'
		});
		jClone.animate({
			'left': left,
			'top': heightOffset,
			'max-width': maxWidth,
			'max-height': maxHeight
		});
	}
	jQuery('div#conversation-blur')
		.animate({
			'opacity': 0.7
		})
		.add(jClone)
			.one('click', function() {
				jQuery('div#conversation-blur').add(jClone).remove();
			});
};

/**
 * Generate a QRCode for OLEFA Apps authentication
 */
function genLoginQRCode(){
    var qrcodeDivs = jQuery("div.qrcode");
    var qrcode = '';
    var id = '';
    var token = '';
    for (var i=0;i<qrcodeDivs.length;i++) {
    	qrcode = new QRCode(qrcodeDivs[i], {width : 100,height : 100,correctLevel: QRCode.CorrectLevel.L});
    	id = jQuery(qrcodeDivs[i]).attr('data-id');
    	token = jQuery(qrcodeDivs[i]).attr('data-token');
    	qrcode.makeCode(id+';'+token);
    }
};

