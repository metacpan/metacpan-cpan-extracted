(function() {
	var dialog;
	var slider;

	evtLoaded.subscribe(function() {
		YAHOO.util.Event.addListener('btn_date_to_execute', 'click', onClockButtonClick);

		slider = YAHOO.widget.Slider.getHorizSlider('priority-slider-bg', 'priority-slider-thumb', 0, 160, 20);

		slider.subscribe('change', onPriorityChange);
		slider.setValue(80);

		var button = new YAHOO.widget.Button('button_enqueue');

		button.subscribe('click', onEnqueueClick);
	});

	function onEnqueueClick()
	{
		YAHOO.util.Dom.get('enqueue').submit();
	}

	function create_dialog()
	{
		var now		= new Date;
		var div		= document.createElement('div');
		var divdate	= document.createElement('div');
		var divtime	= document.createElement('div');

		div.id		= 'container_datetime';
		divdate.id	= 'container_date';
		divtime.id	= 'container_time';

		cal		= new YAHOO.widget.Calendar(divdate, { iframe: false, mindate: now });
		dialog	= new YAHOO.widget.Dialog
		(
			'container_dialog',
			{
				zIndex:					5,
				visible:				false,
				constraintoviewport:	true,
				draggable:				true,
				buttons:
				[
					{ text: 'Now',		handler: datetime_reset },
					{ text: 'OK',		handler: onDateTimeOK, isDefault: true },
					{ text: 'Cancel',	handler: function() { dialog.hide() } }
				]
			}
		);

		cal.renderEvent.subscribe(function() { dialog.fireEvent('changeContent') });
		dialog.showEvent.subscribe(function() { if (YAHOO.env.ua.ie) dialog.fireEvent('changeContent') });

		hour	= document.createElement('select');
		minute	= document.createElement('select');
		ampm	= document.createElement('select');

		for (var i = 1; i <= 12; i++)
			hour.options.add(new Option(i, i, 0, 0));
		for (var i = 0; i <= 59; i++)
			minute.options.add(new Option(i < 10 ? '0' + i : i, i < 10 ? '0' + i : i, 0, 0));

		ampm.options.add(new Option('AM', 'AM', 0, 0));
		ampm.options.add(new Option('PM', 'PM', 0, 0));

		datetime_reset();

		divtime.appendChild(hour);
		divtime.appendChild(document.createTextNode(' : '));
		divtime.appendChild(minute);
		divtime.appendChild(document.createTextNode(' '));
		divtime.appendChild(ampm);

		div.appendChild(divdate);
		div.appendChild(divtime);

		dialog.setHeader('date/time to execute');
		dialog.setBody(div);

		dialog.render(document.body);
		cal.render();

		YAHOO.util.Event.addListener('btn_date_to_execute', 'click', onClockButtonClick);
	};

	function datetime_reset()
	{
		var now = new Date;

		cal.cfg.setProperty('pagedate', cal.today);
		cal.select(cal.today);
		cal.render();

		hour.selectedIndex = now.getHours() > 12 ? now.getHours() - 12 - 1 : now.getHours() - 1;
		minute.selectedIndex = now.getMinutes();
		ampm.selectedIndex = now.getHours() > 12 ? 1 : 0;
	}

	function onClockButtonClick(e)
	{
		if (!dialog)
			create_dialog();

		dialog.cfg.setProperty('xy', YAHOO.util.Event.getXY(e));
		dialog.show();
	}

	function onDateTimeOK()
	{
		var obj = YAHOO.util.Dom.get('date_to_execute');

		var dt = cal.getSelectedDates()[0];
		var yr = dt.getFullYear();
		var mo = dt.getMonth() + 1;
		var da = dt.getDate();
		var hr = hour.value;
		var mn = minute.value;

		if (ampm.value == 'PM') hr = parseInt(hr) + 12;

		if (hr < 10) hr = '0' + hr;
		if (mo < 10) mo = '0' + mo;
		if (da < 10) da = '0' + da;

		obj.value = yr + '-' + mo + '-' + da + 'T' + hr + ':' + mn + ':' + '00';

		dialog.hide();
	}

	function onPriorityChange()
	{
		var input	= YAHOO.util.Dom.get('priority');
		var obj		= YAHOO.util.Dom.get('priority-text');
		var node	= obj.firstChild || document.createTextNode();
		var value	= Math.round(slider.getValue() / 20);

		var labels	=
		[
			'bottom of the pile',
			'lowest',
			'lower',
			'low',
			'normal',
			'high',
			'higher',
			'highest',
			'as soon as possible'
		];

		node.nodeValue	= labels[value];
		input.value		= value + 1;

		if (!obj.firstChild)
			obj.appendChild(node);
	}
})();
