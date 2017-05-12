package Gtk2::Ex::ICal::Recur;

our $VERSION = '0.06';

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Simple::Menu;
use Gtk2::Ex::Simple::List;
use Glib qw /TRUE FALSE/;
use Data::Dumper;
use Gtk2::Ex::ICal::Recur::Selection;
use DateTime::Event::ICal;
use Gtk2::Ex::CalendarButton;

###########################################################
# There are four public methods. The rest are all private #
###########################################################

sub new {
	my ($class) = @_;
	my $self  = {};
	$self->{freqspinbutton} = Gtk2::SpinButton->new_with_range(1,100,1);
	$self->{freqcombobox} = Gtk2::ComboBox->new_text();	
	$self->{recurrencepatterntable} = Gtk2::Table->new(1,1,FALSE);
	$self->{recurbox}->{hbox} = undef;
	$self->{recurbox}->{buttons} = undef;
	$self->{freqchoices} = [ 
		{ 'label' => 'Year(s)' , 'code' => 'yearly' },
		{ 'label' => 'Month(s)', 'code' => 'monthly' },
		{ 'label' => 'Week(s)' , 'code' => 'weekly' },
		{ 'label' => 'Day(s)'  , 'code' => 'daily' },
	];
	$self->{exceptionslist} = undef;
	$self->{icalselection} = Gtk2::Ex::ICal::Recur::Selection->new;
	bless ($self, $class);
	$self->{widget} = $self->package_all;
	return $self;
}

sub update_preview {
	my ($self) = @_;
	my $temp = [
		['Generating Preview'],
		['Please wait...'],
	];
	my $none= [
		['No dates matching'],
		['your criteria...'],
	];
	@{$self->{preview}->{slist}->{data}} = @$temp;
	$self->{preview}->{slist}->show_all;
	$self->{model} = $self->get_model;
	my $date_list = $self->generate_date_list($self->{model});
	if ($#{@$date_list} >= 0) {
		@{$self->{preview}->{slist}->{data}} = @$date_list;
	} else {
		@{$self->{preview}->{slist}->{data}} = @$none;
	}
}

sub set_model {
	my ($self, $model) = @_;
	$self->{model} = $model;
	$self->{recurbox}->{hbox} = undef;
	my $temphash = $self->controller(0, 0);
	$self->{recurbox}->{hbox}->[0]->[0] = $self->create_box(0,0,$temphash);
	$self->packbox();
	$self->{freqspinbutton}->set_value($model->{interval});
	my $mapped = { 'yearly' => 0, 'monthly' => 1, 'weekly' => 2, 'daily' => 3 };
	$self->{freqcombobox}->set_active($mapped->{$model->{freq}});
	if ($model->{freq} eq 'yearly') {
		if ($model->{bymonth}) {
			$self->set_month_of_the_year($model, 0);
			if ($model->{bymonthday}) {
				$self->set_month_day_by_day($model, 1);
			} elsif ($model->{byday}) {
				$self->set_month_day_by_week($model, 1);
			}
		} elsif ($model->{byyearday}) {
			$self->set_day_of_the_year($model, 0);
		} elsif ($model->{byweekno}) {
			$self->set_weeknumber_of_the_year($model, 0);
			if ($model->{byday}) {
				$self->set_week_day($model, 1);
			}
		}
	} elsif ($model->{freq} eq 'monthly') {
		if ($model->{bymonthday}) {
			$self->set_month_day_by_day($model, 0);
		} elsif ($model->{byday}) {
			$self->set_month_day_by_week($model, 0);
		}
	} elsif ($model->{freq} eq 'weekly') {
		if ($model->{byday}) {
			$self->set_week_day($model, 0);
		}
	} elsif ($model->{freq} eq 'daily') {
		# Save this for hourly
	}
	if ($model->{dtstart}) {
	    $self->{'dtstart'} = $model->{'dtstart'};
	    $self->{duration}->{dtstart}->set_date(
	        _transform_date($model->{dtstart})
	    );
	}	
	if ($model->{dtend}) {
	    $self->{'dtend'} = $model->{'dtend'};
	    $self->{duration}->{dtend}->set_date(
	        _transform_date($model->{dtend})
	    );
		$self->{duration}->{end_on_radio}->set_active(TRUE);
	} elsif ($model->{count}) {
		$self->{duration}->{count}->set_value($model->{count});
		$self->{duration}->{end_after_radio}->set_active(TRUE);
	}
}

sub _transform_date {
    my ($datehash) = @_;
    my $datearray = [
        $datehash->{year},
        $datehash->{month},
        $datehash->{day},
    ];
    return $datearray;                       
}

sub get_model {
	my ($self) = @_;
	my $model;
	my $freqcombochoice = $self->{freqchoices}->[$self->{freqcombobox}->get_active()]->{'code'};
	$model->{freq} = $freqcombochoice;
	$model->{interval} = $self->{freqspinbutton}->get_value;
	foreach my $level (@{$self->{recurbox}->{buttons}}) {
		my $i = 0;
		foreach my $count (@$level) {
			my $type = $count->{type};
			my $code = $count->{code};
			$model->{$type}->[$i++] = $code;
		}
	}
	$model->{'dtstart'} = $self->{'dtstart'};
	if ($self->{duration}->{end_on_radio}->get_active) {
		$model->{'dtend'} = $self->{'dtend'} if $self->{'dtend'};
	} else {
		$model->{'count'} = $self->{duration}->{'count'}->get_value if $self->{duration}->{'count'};	
	}
	my @temp = @{$self->{exceptionslist}->{data}};
	my @exceptions = ();
	foreach my $x (@temp) {
		my ($mon, $day, $junk, $year) = split /\W/, $x->[0];
		my $monthlist = month();
		my $i = 0;
		my %hash = map {$_ => $i++} @$monthlist;
		my $date = { month => $hash{$mon}, day => $day, year => $year};
		push @exceptions, $date;
	}
	$model->{exceptions} = \@exceptions;
	$self->{model} = $model;
	return $model;
}

##############################################
# All methods below this are private methods #
##############################################

sub generate_date_list {
	my ($self, $origmodel) = @_;
	my $model;
	my @list;
	$model->{dtstart} = hash_to_datetime($origmodel->{dtstart}) if ($origmodel->{dtstart});
	$model->{dtend} = hash_to_datetime($origmodel->{dtend}) if ($origmodel->{dtend});
	$model->{count} = $origmodel->{count} if ($origmodel->{count});
	$model->{freq} = $origmodel->{freq} if ($origmodel->{freq});
	$model->{interval} = $origmodel->{interval} if ($origmodel->{interval});
	$model->{byday} = $origmodel->{byday} if ($origmodel->{byday});
	$model->{byyearday} = $origmodel->{byyearday} if ($origmodel->{byyearday});
	$model->{bymonthday} = $origmodel->{bymonthday} if ($origmodel->{bymonthday});
	$model->{byweekno} = $origmodel->{byweekno} if ($origmodel->{byweekno});
	$model->{bymonth} = $origmodel->{bymonth} if ($origmodel->{bymonth});
	my $set = DateTime::Event::ICal->recur(%$model);
	my $iter = $set->iterator;
	my $exceptions = $self->{model}->{exceptions};
	my $hash;
	foreach my $x (@$exceptions) {
		my $year = $x->{year};
		my $mon = $x->{month};
		my $day= $x->{day};
		$hash->{"$year\-$mon\-$day"} = 1;
	}
	my $i = 0;
	while ( my $dt = $iter->next ) {
		my $year = $dt->year;
		my $mon = $dt->month;
		my $day= $dt->day;
		my $month = month()->[$mon-1];
		$mon--;
		push @list, "$month $day\, $year" unless $hash->{"$year\-$mon\-$day"};
	}
	return \@list;
}

sub hash_to_datetime {
	my ($hash) = @_;
	my $dt = DateTime->new(%$hash);
	return $dt;
}

sub package_all {
	my ($self) = @_;
	my $exceptions = $self->exceptions();
	my $duration = $self->duration();
	my $preview = $self->preview();
	enable_dnd($self->{preview}->{slist}, $self->{exceptionslist});
	my $exceptions_frame = Gtk2::Frame->new('Exceptions');
	my $duration_frame = Gtk2::Frame->new('Duration');
	my $recur_frame = Gtk2::Frame->new('Recurrence Pattern');
	my $preview_frame = Gtk2::Frame->new('Preview');

	my $vbox = Gtk2::VBox->new(FALSE);
	$vbox->pack_start($duration, FALSE, FALSE, 0);
	$duration_frame->add($vbox);
	$exceptions_frame->add($exceptions);
	$recur_frame->add($self->get_widget);
	$preview_frame->add($preview);

	my $hbox = Gtk2::HBox->new(FALSE);
	$hbox->pack_start($duration_frame, FALSE, FALSE, 0);
	$hbox->pack_start($exceptions_frame, TRUE, TRUE, 0);

	my $mainvbox = Gtk2::VBox->new(FALSE);
	$mainvbox->pack_start($recur_frame, TRUE, TRUE, 0);
	$mainvbox->pack_start($hbox, FALSE, FALSE, 0);

	my $mainhbox = Gtk2::HBox->new(FALSE);
	$mainhbox->pack_start($mainvbox, TRUE, TRUE, 0);
	$mainhbox->pack_start($preview_frame, TRUE, TRUE, 0);
	
	return $mainhbox;
}

sub preview {
	my ($self) = @_;
	my $vbox = Gtk2::VBox->new(FALSE);
	my $slist = Gtk2::Ex::Simple::List->new ('Exceptions'    => 'text',);
	$slist->set_headers_visible(FALSE);
	$slist->get_selection->set_mode ('multiple');
	$self->{preview}->{slist} = $slist;
	my $scroll = Gtk2::ScrolledWindow->new;
	$scroll->set_policy('never','automatic');
	$scroll->add($slist);
	my $cal = Gtk2::Calendar->new;
	$vbox->pack_start($scroll, TRUE, TRUE, 0);
	#$vbox->pack_start($cal, FALSE, FALSE, 0);
	return $vbox;
}

sub duration {
	my ($self) = @_;
	my $table = Gtk2::Table->new(3, 4, FALSE);
	
	$self->{duration}->{dtstart} = Gtk2::Ex::CalendarButton->new;
	$self->{duration}->{dtstart}->signal_connect ('date-changed' => 
	    sub {
	        my ($calbutton) = @_;
	        my $date = $calbutton->get_date;
	        my $hash = {
	            year => $date->[0],
	            month => $date->[1],
	            day => $date->[2]
	        };
	        $self->{dtstart} = $hash;
	    }
	);
	
	$self->{duration}->{dtend} = Gtk2::Ex::CalendarButton->new;
	$self->{duration}->{dtend}->signal_connect ('date-changed' => 
	    sub {
	        my ($calbutton) = @_;
	        my $date = $calbutton->get_date;
	        my $hash = {
	            year => $date->[0],
	            month => $date->[1],
	            day => $date->[2]
	        };
	        $self->{dtend} = $hash;
	    }
	);	
		
	my $start_date_label = Gtk2::Label->new('Starting on');
	$start_date_label->set_alignment(0, 0.5);	
	
	my $end_on_label = Gtk2::Label->new('and ending on');
	$end_on_label->set_alignment(0, 0.5);	
	
	my $end_after_label = Gtk2::Label->new('and ending after');
	$end_after_label->set_alignment(0, 0.5);
	my $count = Gtk2::SpinButton->new_with_range(1,100,1);
	$self->{duration}->{count} = $count;
	my $occurrences_label = Gtk2::Label->new(' occurrences ');
	$occurrences_label->set_alignment(0, 0.5);	
	
	$table->attach($start_date_label,1,2,0,1,'fill','fill',0,0);
	$table->attach($self->{duration}->{dtstart}->{button},2,3,0,1,'fill','fill',0,0);
	
	my $end_on_radio = Gtk2::RadioButton->new;
	my $end_after_radio = Gtk2::RadioButton->new($end_on_radio);
	$self->{duration}->{end_on_radio} = $end_on_radio;
	$self->{duration}->{end_after_radio} = $end_after_radio;
	
	$self->{duration}->{dtend}->{button}->set_sensitive($end_on_radio->get_active);
	$end_on_label->set_sensitive($end_on_radio->get_active);
	$end_after_label->set_sensitive($end_after_radio->get_active);
	$count->set_sensitive($end_after_radio->get_active);
	$occurrences_label->set_sensitive($end_after_radio->get_active);

	$end_on_radio->signal_connect('toggled' => 
		sub {
			$self->{duration}->{dtend}->{button}->set_sensitive($end_on_radio->get_active);
			$end_on_label->set_sensitive($end_on_radio->get_active);
			$end_after_label->set_sensitive($end_after_radio->get_active);
			$count->set_sensitive($end_after_radio->get_active);
			$occurrences_label->set_sensitive($end_after_radio->get_active);
		}
	);
	
	$table->attach_defaults($end_on_radio,0,1,1,2);
	$table->attach_defaults($end_on_label,1,2,1,2);
	$table->attach_defaults($self->{duration}->{dtend}->{button},2,3,1,2);

	$table->attach_defaults($end_after_radio,0,1,2,3);
	$table->attach_defaults($end_after_label,1,2,2,3);
	$table->attach_defaults($count,2,3,2,3);
	$table->attach_defaults($occurrences_label,3,4,2,3);
	return $table;
}

sub exceptions {
	my ($self) = @_;
	my $slist = Gtk2::Ex::Simple::List->new ('Exceptions'    => 'text',);
	$slist->get_selection->set_mode ('multiple');
	$slist->set_headers_visible(FALSE);
	my $buttonbox = Gtk2::HBox->new;
	my $addbutton = Gtk2::Button->new_from_stock('gtk-add');
	my $removebutton = Gtk2::Button->new_from_stock('gtk-remove');
	$addbutton->signal_connect('button-release-event' => 
		sub {
			my ($self, $event) = @_;
			my $cal = Gtk2::Calendar->new;
			my $calwindow = Gtk2::Window->new('popup');
			my $vbox = Gtk2::VBox->new;
			my $ok = Gtk2::Button->new_from_stock('gtk-ok');
			my $cancel= Gtk2::Button->new_from_stock('gtk-cancel');
			$ok->signal_connect('clicked' => 
				sub {
					my ($year, $month, $day) = $cal->get_date;
					$month = month()->[$month];
					#push @{$slist->{data}}, ["(not yet implemented)"] if ($#{@{$slist->{data}}} <= 0);
					push @{$slist->{data}}, ["$month $day\, $year"];
					$calwindow->hide;
				}
			);
			$cancel->signal_connect('clicked' => 
				sub {
					$calwindow->hide;
				}
			);
			my $hbox = Gtk2::HBox->new;
			$hbox->pack_start($ok, TRUE, TRUE, 0);
			$hbox->pack_start($cancel, TRUE, TRUE, 0);
			$vbox->pack_start($cal, TRUE, TRUE, 0);
			$vbox->pack_start($hbox, TRUE, TRUE, 0);
			$calwindow->add($vbox);
			$calwindow->set_position('mouse');
			$calwindow->show_all;
		}
	);
	$removebutton->signal_connect('button-release-event' => 
		sub {
			my @sel = $slist->get_selected_indices;
			my @temp = @{$slist->{data}};
			my @newlist;
			my %hash = map { $_ => 1 } @sel;
			for (my $i=0; $i<=$#temp; $i++) {
				push @newlist, [$temp[$i]->[0]] unless $hash{$i};
			}
			@{$slist->{data}} = ();
			foreach my $x (@newlist) {
				push @{$slist->{data}}, $x;
			}			
		}
	);
	$buttonbox->pack_start($addbutton, TRUE, TRUE, 0);
	$buttonbox->pack_start($removebutton, TRUE, TRUE, 0);
	my $vbox = Gtk2::VBox->new;
	my $scroll = Gtk2::ScrolledWindow->new;
	$scroll->set_policy('never','automatic');
	$scroll->add($slist);
	$self->{exceptionslist} = $slist;
	$vbox->pack_start($scroll, TRUE, TRUE, 0);
	$vbox->pack_start($buttonbox, FALSE, FALSE, 0);
	return $vbox;
}

sub month {
	return [
		'Jan',
		'Feb',
		'Mar',
		'Apr',
		'May',
		'Jun',
		'Jul',
		'Aug',
		'Sep',
		'Oct',
		'Nov',
		'Dec',
	];
}


sub get_widget {
	my ($self) = @_;
	foreach my $choice (@{$self->{freqchoices}}) {
		$self->{freqcombobox}->append_text($choice->{'label'});	
	}
	my $freqhbox = Gtk2::HBox->new(FALSE);
	$freqhbox->pack_start(Gtk2::Label->new('Occurs every'), FALSE, FALSE, 0);
	$freqhbox->pack_start($self->{freqspinbutton}, FALSE, FALSE, 0);
	$freqhbox->pack_start($self->{freqcombobox}, FALSE, FALSE, 0);
	
	$self->{freqcombobox}->signal_connect('changed' => 
		sub {
			$self->{recurbox}->{hbox} = undef;
			$self->{recurbox}->{buttons} = undef;
			my $temphash = $self->controller(0, 0);
			$self->{recurbox}->{hbox}->[0]->[0] = $self->create_box(0,0,$temphash);
			$self->packbox();
		}
	);
	my $scroll = Gtk2::ScrolledWindow->new;
	$scroll->add_with_viewport($self->{recurrencepatterntable});
	$scroll->set_policy('never', 'automatic');
	$self->{recurrencepatterntable}->set_col_spacings(1);
	$self->{recurrencepatterntable}->set_row_spacings(1);
	
	my $vbox = Gtk2::VBox->new(FALSE, 5);
	$vbox->pack_start($freqhbox, FALSE, FALSE, 0);
	$vbox->pack_start($scroll, TRUE, TRUE, 0);
	return $vbox;
}


sub set_month_of_the_year {
	my ($self, $model, $level) = @_;
	my @months = @{$model->{bymonth}};
	my $list = $self->{icalselection}->month_of_the_year();
	my $hash;
	for (my $i=0; $i<=$#{@$list}; $i+=2) {
		my $x = $list->[$i+1]->{callback_data};
		$hash->{$x->[2]} = $x->[1];
	}
	$self->update_ui_from_model(\@months, $hash, '/^/by month of the year/', $level);
}

sub set_day_of_the_year {
	my ($self, $model, $level) = @_;
	my @yeardays = @{$model->{byyearday}};
	my $list = $self->{icalselection}->day_of_the_year();
	my $hash;
	for (my $i=0; $i<=$#{@$list}; $i+=2) {
		my $x = $list->[$i+1]->{children};				
		for (my $j=0; $j<=$#{@$x}; $j+=2) {
			my $y = $x->[$j+1]->{callback_data};
			$hash->{$y->[2]} = $list->[$i].'/'.$y->[1];
		}
	}
	$self->update_ui_from_model(\@yeardays, $hash, '/^/by day of the year/', $level);
}

sub set_weeknumber_of_the_year {
	my ($self, $model, $level) = @_;
	my @weeknums = @{$model->{byweekno}};
	my $list = $self->{icalselection}->weeknumber_of_the_year();
	my $hash;
	for (my $i=0; $i<=$#{@$list}; $i+=2) {
		my $x = $list->[$i+1]->{children};				
		for (my $j=0; $j<=$#{@$x}; $j+=2) {
			my $y = $x->[$j+1]->{callback_data};
			$hash->{$y->[2]} = $list->[$i].'/'.$y->[1];
		}
	}
	$self->update_ui_from_model(\@weeknums, $hash, '/^/by weeknumber of the year/', $level);
}

sub set_week_day {
	my ($self, $model, $level) = @_;
	my @weekdays = @{$model->{byday}};
	my $list = $self->{icalselection}->week_day();
	my $hash;
	for (my $i=0; $i<=$#{@$list}; $i+=2) {
		my $x = $list->[$i+1]->{callback_data};
		$hash->{$x->[2]} = $x->[1];
	}
	$self->update_ui_from_model(\@weekdays, $hash, '/^/', $level);
}

sub set_month_day_by_day {
	my ($self, $model, $level) = @_;
	my @monthdays = @{$model->{bymonthday}};
	my $list = $self->{icalselection}->month_day_by_day();
	my $hash;
	for (my $i=0; $i<=$#{@$list}; $i+=2) {
		my $x = $list->[$i+1]->{children};				
		for (my $j=0; $j<=$#{@$x}; $j+=2) {
			my $y = $x->[$j+1]->{callback_data};
			$hash->{$y->[2]} = $list->[$i].'/'.$y->[1];
		}
	}
	$self->update_ui_from_model(\@monthdays, $hash, '/^/by day/', $level);
}

sub set_month_day_by_week {
	my ($self, $model, $level) = @_;
	my @monthdays = @{$model->{byday}};
	my $list = $self->{icalselection}->month_day_by_week();
	my $hash;
	for (my $i=0; $i<=$#{@$list}; $i+=2) {
		my $x = $list->[$i+1]->{children};				
		for (my $j=0; $j<=$#{@$x}; $j+=2) {
			my $y = $x->[$j+1]->{callback_data};
			$hash->{$y->[2]} = $list->[$i].'/'.$y->[1];
		}
	}
	$self->update_ui_from_model(\@monthdays, $hash, '/^/by week day/', $level);
}

sub update_ui_from_model {
	my ($self, $list, $hash, $string, $level) = @_;
	for (my $i=0; $i<=$#{@$list}; $i++) {
		$self->{recurbox}->{buttons}->[$level]->[$i]->{simplemenu}->get_widget($string.$hash->{$list->[$i]})->activate;
		$self->{recurbox}->{buttons}->[$level]->[$i]->{next}->set_sensitive(FALSE);
		if ($i<$#{@$list}) {
			$self->addbuttonclicked($level, $i);
			$self->{recurbox}->{buttons}->[$level]->[$i]->{add}->set_sensitive(FALSE);
			$self->{recurbox}->{buttons}->[$level]->[$i]->{remove}->set_sensitive(FALSE);
		} else {
			$self->nextbuttonclicked($level, $i);
		}
	}
}


sub controller {
	my ($self, $level, $count) = @_;
	my $temphash = undef;
	if ($level == 0) {
		my $freqcombochoice = $self->{freqchoices}->[$self->{freqcombobox}->get_active()]->{'code'};
		if ($freqcombochoice eq 'yearly') {		
			$temphash = $self->month_or_day_of_the_year($level,$count);
		} elsif ($freqcombochoice eq 'monthly') {
			$temphash = $self->day_of_the_month($level,$count);
		} elsif ($freqcombochoice eq 'weekly') {
			$temphash = $self->day_of_the_week($level,$count);
		} elsif ($freqcombochoice eq 'daily') {
		}
	} elsif ($level == 1) {
		my $parent = $self->{recurbox}->{buttons}->[$level-1]->[0]->{type};
		if ($parent eq 'bymonth') {
			$temphash = $self->day_of_the_month($level,$count);
		} elsif ($parent eq 'byyearday') {
		
		} elsif ($parent eq 'byweekno') {			
			$temphash = $self->day_of_the_week($level,$count);
		}
	}
	if (!$temphash) {
		# print "controller called with $level $count Un-implemented\n";
	}
	return $temphash;
}

sub packbox {
	my ($self) = @_;
	my $rows = 0;
	foreach my $level (@{$self->{recurbox}->{hbox}}) {
		foreach my $count (@$level) {
			$rows++ if ($count);
		}
	}
	# First I will clear the contents of the $table
	my @children = $self->{recurrencepatterntable}->get_children;
	foreach my $child (@children) {
		$self->{recurrencepatterntable}->remove($child);
	}

	# Now I will resize the table	
	$self->{recurrencepatterntable}->resize($rows,5) if ($rows > 0);
	
	my $row = 0;
	foreach my $level (@{$self->{recurbox}->{hbox}}) {
		foreach my $count (@$level) {
			my $col = 0;
			foreach my $widget (@$count) {
				if ($widget) {
					$self->{recurrencepatterntable}->attach($widget, $col, $col+1, $row, $row+1, 'fill', 'fill', 0, 0) ;
					$col++;
				}
			}
			$row++;
		}
	}
	$self->{recurrencepatterntable}->show_all;
}

sub create_box {
	my ($self, $level, $count, $temphash) = @_;
	return undef unless $temphash;

	my $box_as_array = [];
	my $hbox = Gtk2::HBox->new(FALSE);
	my $tooltips = Gtk2::Tooltips->new;

	my $addbutton = Gtk2::Button->new;
	my $removebutton = Gtk2::Button->new;
	my $nextbutton = Gtk2::Button->new;

	$tooltips->set_tip($addbutton, 'add another', undef);
	$tooltips->set_tip($removebutton, 'remove this', undef);
	$tooltips->set_tip($nextbutton, 'continue to next level', undef);

	my $add_icon = Gtk2::Image->new_from_stock('gtk-add', 'GTK_ICON_SIZE_BUTTON');
	my $remove_icon = Gtk2::Image->new_from_stock('gtk-remove', 'GTK_ICON_SIZE_BUTTON');
	my $next_icon = Gtk2::Image->new_from_stock('gtk-go-forward', 'GTK_ICON_SIZE_BUTTON');
	
	$addbutton->set_image($add_icon);
	$removebutton->set_image($remove_icon);
	$nextbutton->set_image($next_icon);
	
	$self->{recurbox}->{buttons}->[$level]->[$count]->{add} = $addbutton;
	$self->{recurbox}->{buttons}->[$level]->[$count]->{next} = $nextbutton;
	$self->{recurbox}->{buttons}->[$level]->[$count]->{remove} = $removebutton;	

	$addbutton->set_sensitive(FALSE);
	$nextbutton->set_sensitive(FALSE);
	$removebutton->set_sensitive(FALSE);
	
	$addbutton->signal_connect('clicked' => 
		sub {
			$addbutton->set_sensitive(FALSE);
			$nextbutton->set_sensitive(FALSE);
			$removebutton->set_sensitive(FALSE);
			$self->addbuttonclicked($level, $count);
		}
	);
	$nextbutton->signal_connect('clicked' => 
		sub {
			$nextbutton->set_sensitive(FALSE);
			$self->nextbuttonclicked($level, $count);
		}
	);
	$removebutton->signal_connect('clicked' => 
		sub {
			$self->removebuttonclicked($level, $count);
		}
	);
	
	$self->{recurbox}->{buttons}->[$level]->[$count]->{simplemenu} = $temphash->{simplemenu};	
	$self->{recurbox}->{buttons}->[$level]->[$count]->{label} = $temphash->{label};	
	push @$box_as_array, $temphash->{simplemenu}->{widget};
	push @$box_as_array, $temphash->{label};
	push @$box_as_array, $addbutton;
	push @$box_as_array, $removebutton;
	push @$box_as_array, $nextbutton;

	return $box_as_array;
}

sub nextbuttonclicked {
	my ($self, $level, $count) = @_;
	# If there are rows underneath
	return if ($#{@{$self->{recurbox}->{hbox}->[$level+1]}} >= 0);	
	my $currentcount = $#{$self->{recurbox}->{hbox}->[$level+1]};
	my $temphash = $self->controller($level+1, $currentcount+1);
	$self->{recurbox}->{hbox}->[$level+1]->[$currentcount+1] = $self->create_box($level+1, $currentcount+1, $temphash);
	$self->packbox();
}

sub addbuttonclicked {
	my ($self, $level, $count) = @_;
	my $temphash = $self->controller($level, $count+1);
	$self->{recurbox}->{buttons}->[$level]->[$count]->{simplemenu}->{widget}->set_sensitive(FALSE);
	if ($level > 0) {
		my $count = $#{$self->{recurbox}->{hbox}->[$level-1]};
		$self->{recurbox}->{buttons}->[$level-1]->[$count]->{next}->set_sensitive(FALSE);
	}
	$self->{recurbox}->{hbox}->[$level]->[$count+1] = $self->create_box($level, $count+1, $temphash);
	if ($#{@{$self->{recurbox}->{hbox}->[$level+1]}} >= 0) {
		$self->{recurbox}->{buttons}->[$level]->[$count+1]->{next}->set_sensitive(FALSE);		
	}
	$self->packbox();
}

sub removebuttonclicked {
	my ($self, $level, $count) = @_;
	delete($self->{recurbox}->{hbox}->[$level]->[$count]);
	delete($self->{recurbox}->{buttons}->[$level]->[$count]);
	if ($count>0) {
		$self->{recurbox}->{buttons}->[$level]->[$count-1]->{simplemenu}->{widget}->set_sensitive(TRUE);
		$self->{recurbox}->{buttons}->[$level]->[$count-1]->{add}->set_sensitive(TRUE);
		if (!$self->{recurbox}->{hbox}->[$level+1]) {
			$self->{recurbox}->{buttons}->[$level]->[$count-1]->{next}->set_sensitive(TRUE);
		}
		$self->{recurbox}->{buttons}->[$level]->[$count-1]->{remove}->set_sensitive(TRUE);
	} else {
		for (my $i=$level+1; $i<=$#{@{$self->{recurbox}->{hbox}}}; $i++) {
			delete($self->{recurbox}->{hbox}->[$i]);
		}
		my $lastcount = $#{@{$self->{recurbox}->{hbox}->[$level-1]}};
		$self->{recurbox}->{buttons}->[$level-1]->[$lastcount]->{next}->set_sensitive(TRUE);
	}
	$self->packbox();
}

sub _source_drag_data_get {
	my ($widget, $context, $data, $info, $time) = @_;
	$data->set ($data->target, 0, 0);
}

sub _drag_data_received {
	my ($tolist, $context, $x, $y, $data, $info, $time, $fromlist) = @_;
	my @selectedindices = $fromlist->get_selected_indices;
	_move_from_to ($fromlist, $tolist, \@selectedindices);
}

sub _move_from_to {
	my ($fromlist, $tolist, $selectedindices) = @_;
	# Populate the tolist
	foreach my $i (@$selectedindices) {
		push @{$tolist->{data}}, $fromlist->{data}->[$i];
	}
	my %hash = map { $_ => 1 } @$selectedindices;
	my @temp;
	# Remove entries from fromlist
	for (my $i=0; $i<=$#{@{$fromlist->{data}}}; $i++) {
		push @temp, $fromlist->{data}->[$i]->[0] unless exists($hash{$i});
	}
	@{$fromlist->{data}} = @temp;	
}

sub enable_dnd {
	my ($fromlist, $tolist) = @_;
	$fromlist->drag_source_set (['button1_mask', 'button3_mask'],['copy', 'move'], 
		{'target' => "STRING", 'flags' => [], 'info' => 0});
	$tolist->drag_dest_set('all', ['copy', 'move'], 
		{'target' => "STRING", 'flags' => [], 'info' => 0});
	$fromlist->signal_connect ('drag-data-get', \&_source_drag_data_get);
	$tolist->signal_connect('drag-data-received', \&_drag_data_received, $fromlist);	
}

sub day_of_the_month {
	my ($self, $level, $count) = @_;
	my $label = Gtk2::Label->new;
	$label->set_markup('<span foreground="red">choose a day/weekday</span>');	
	$label->set_alignment(0, 0.5);	
	
	my $tooltips = Gtk2::Tooltips->new;
		
	my $callback = sub {
		my ($data) = @_;
		my $type = $data->[0];
		my $text = $data->[1];
		my $code = $data->[2];
		$self->{recurbox}->{buttons}->[$level]->[$count]->{code} = $code;
		$self->{recurbox}->{buttons}->[$level]->[$count]->{type} = $type;
		$text = "and $text" if ($count > 0);
		$label->set_label($text);
		$tooltips->set_tip(
    		$self->{recurbox}->{buttons}->[$level]->[$count]->{add},
    		'add another day',
    		undef
		);
		$tooltips->set_tip(
    		$self->{recurbox}->{buttons}->[$level]->[$count]->{remove},
    		'remove this day',
    		undef
		);
		$self->{recurbox}->{buttons}->[$level]->[$count]->{add}->set_sensitive(TRUE);
		#$self->{recurbox}->{buttons}->[$level]->[$count]->{next}->set_sensitive(TRUE);
		$self->{recurbox}->{buttons}->[$level]->[$count]->{remove}->set_sensitive(TRUE);
	};
	my $menu_tree = [
		'^'  => {
			item_type  => '<Branch>',
			children => [
				'by day' => {
					item_type  => '<Branch>',
					children => $self->{icalselection}->month_day_by_day($callback),
				},
				'by week day' => {
					item_type  => '<Branch>',
					children => $self->{icalselection}->month_day_by_week($callback),
				},
			],
		},
	];
	if ($count > 0) {
		# Understand the $count=0 selection
		my $brother = $self->{recurbox}->{buttons}->[$level]->[0]->{type};
		if ($brother eq 'byday') {
			$menu_tree = [
				'^'  => {
					item_type  => '<Branch>',
					children => [
						'by week day' => {
							item_type  => '<Branch>',
							children => $self->{icalselection}->month_day_by_week($callback),
						},
					],
				},
			];
		} elsif ($brother eq 'bymonthday'){
			$menu_tree = [
				'^'  => {
					item_type  => '<Branch>',
					children => [
						'by day' => {
							item_type  => '<Branch>',
							children => $self->{icalselection}->month_day_by_day($callback),
						},
					],
				},
			];
		}
	}
	my $menu = Gtk2::Ex::Simple::Menu->new(menu_tree => $menu_tree);
	my $temphash = {};
	$temphash->{simplemenu} = $menu;
	$temphash->{label} = $label;
	return $temphash;
}

sub day_of_the_week {
	my ($self, $level, $count) = @_;
	my $label = Gtk2::Label->new;
	$label->set_markup('<span foreground="red">choose a day of the week</span>');	
	$label->set_alignment(0, 0.5);	
	my $tooltips = Gtk2::Tooltips->new;
	my $callback = sub {
		my ($data) = @_;
		my $type = $data->[0];
		my $text = $data->[1];
		my $code = $data->[2];
		$self->{recurbox}->{buttons}->[$level]->[$count]->{code} = $code;
		$self->{recurbox}->{buttons}->[$level]->[$count]->{type} = $type;
		$text = "and $text" if ($count > 0);
		$label->set_label($text);
		$tooltips->set_tip(
    		$self->{recurbox}->{buttons}->[$level]->[$count]->{add},
    		'add another weekday',
    		undef
		);
		$tooltips->set_tip(
    		$self->{recurbox}->{buttons}->[$level]->[$count]->{remove},
    		'remove this weekday',
    		undef
		);
		$self->{recurbox}->{buttons}->[$level]->[$count]->{add}->set_sensitive(TRUE);
		#$self->{recurbox}->{buttons}->[$level]->[$count]->{next}->set_sensitive(TRUE);
		$self->{recurbox}->{buttons}->[$level]->[$count]->{remove}->set_sensitive(TRUE);
	};
	my $menu_tree = [
		'^'  => {
			item_type  => '<Branch>',
			children => $self->{icalselection}->week_day($callback),
		},
	];

	my $menu = Gtk2::Ex::Simple::Menu->new(menu_tree => $menu_tree);
	my $temphash = {};
	$temphash->{simplemenu} = $menu;
	$temphash->{label} = $label;
	return $temphash;
}

sub month_or_day_of_the_year {
	my ($self, $level, $count) = @_;
	my $label = Gtk2::Label->new;
	$label->set_markup('<span foreground="red">choose a month/week/day</span>');
	$label->set_alignment(0, 0.5);
    my $tooltips = Gtk2::Tooltips->new;
    
	my $callback = sub {
		my ($data) = @_;
		my $type = $data->[0];
		my $text = $data->[1];
		my $code = $data->[2];
		$self->{recurbox}->{buttons}->[$level]->[$count]->{code} = $code;
		$self->{recurbox}->{buttons}->[$level]->[$count]->{type} = $type;
		$text = "and $text" if ($count > 0);
		$label->set_label($text);
		if ($type eq 'bymonth') {
		    $tooltips->set_tip (
		        $self->{recurbox}->{buttons}->[$level]->[$count]->{add},
		        'add another month',
		        undef
		    );
		    $tooltips->set_tip (
		        $self->{recurbox}->{buttons}->[$level]->[$count]->{remove},
		        'remove this month',
		        undef
		    );
			if ($#{@{$self->{recurbox}->{hbox}->[$level+1]}} <= 0) {
				$self->{recurbox}->{buttons}->[$level]->[$count]->{next}->set_sensitive(TRUE);
			}
		} elsif ($type eq 'byyearday') {
    		$tooltips->set_tip(
        		$self->{recurbox}->{buttons}->[$level]->[$count]->{add},
        		'add another day',
        		undef
    		);
    		$tooltips->set_tip(
        		$self->{recurbox}->{buttons}->[$level]->[$count]->{remove},
        		'remove this day',
        		undef
    		);
		} elsif ($type eq 'byweekno') {
    		$tooltips->set_tip(
        		$self->{recurbox}->{buttons}->[$level]->[$count]->{add},
        		'add another week',
        		undef
    		);
    		$tooltips->set_tip(
        		$self->{recurbox}->{buttons}->[$level]->[$count]->{remove},
        		'remove this week',
        		undef
    		);
			if ($#{@{$self->{recurbox}->{hbox}->[$level+1]}} <= 0) {
				$self->{recurbox}->{buttons}->[$level]->[$count]->{next}->set_sensitive(TRUE);
			}
		}
		$self->{recurbox}->{buttons}->[$level]->[$count]->{add}->set_sensitive(TRUE);
		$self->{recurbox}->{buttons}->[$level]->[$count]->{remove}->set_sensitive(TRUE);
	};
	my $menu_tree = [
		'^'  => {
			item_type  => '<Branch>',
			children => [
				'by month of the year' => {
					item_type  => '<Branch>',
					children => $self->{icalselection}->month_of_the_year($callback),
				},
				'by day of the year' => {
					item_type  => '<Branch>',
					children => $self->{icalselection}->day_of_the_year($callback),
				},
				'by weeknumber of the year' => {
					item_type  => '<Branch>',
					children => $self->{icalselection}->weeknumber_of_the_year($callback),
				},
			],
		},
	];
	if ($count > 0) {
		# Understand the $count=0 selection
		my $brother = $self->{recurbox}->{buttons}->[$level]->[0]->{type};
		if ($brother eq 'bymonth') {
			$label->set_markup('<span foreground="red">choose another month</span>');
			$label->set_alignment(0, 0.5);	
			$menu_tree = [
				'^'  => {
					item_type  => '<Branch>',
					children => [
						'by month of the year' => {
							item_type  => '<Branch>',
							children => $self->{icalselection}->month_of_the_year($callback),
						},
					],
				},
			];
		} elsif ($brother eq 'byweekno'){
			$label->set_markup('<span foreground="red">choose another weeknumber</span>');
			$label->set_alignment(0, 0.5);	
			$menu_tree = [
				'^'  => {
					item_type  => '<Branch>',
					children => [
						'by weeknumber of the year' => {
							item_type  => '<Branch>',
							children => $self->{icalselection}->weeknumber_of_the_year($callback),
						},
					],
				},
			];
		} elsif ($brother eq 'byyearday'){
			$label->set_markup('<span foreground="red">choose another day</span>');
			$label->set_alignment(0, 0.5);	
			$menu_tree = [
				'^'  => {
					item_type  => '<Branch>',
					children => [
						'by day of the year' => {
							item_type  => '<Branch>',
							children => $self->{icalselection}->day_of_the_year($callback),
						},
					],
				},
			];
		}				
	}

	my $menu = Gtk2::Ex::Simple::Menu->new(menu_tree => $menu_tree);
	my $temphash = {};
	$temphash->{simplemenu} = $menu;
	$temphash->{label} = $label;
	return $temphash;
}

1;

__END__

=head1 NAME

Gtk2::Ex::ICal::Recur - A widget for scheduling a recurring 
set of 'events' (events in the calendar sense). Like a meeting
appointment for example, on all mondays and thursdays for the next 3
months. Kinda like Evolution or Outlook meeting schedule.

=head1 DESCRIPTION

=head1 SYNOPSIS

	my $recur = Gtk2::Ex::ICal::Recur->new;
	my $model = {
		'dtstart' => { 
			year => 2000,
			month  => 6,
			day    => 20,
		},
		'count' => 17,
		'freq' => 'yearly',
		'interval' => '5',
		'byweekno' => [1, -1],
		'byday' => ['su','fr', 'mo'],
	};
	$recur->set_model($model);

	my $window = Gtk2::Window->new;
	$window->signal_connect(destroy => sub { Gtk2->main_quit; });

	my $vbox = Gtk2::VBox->new(FALSE);
	my $hbox = Gtk2::HBox->new(FALSE);
	my $preview = Gtk2::Button->new_from_stock('gtk-preview');
	$preview->signal_connect('clicked' => 
		sub {
			$recur->update_preview;		
		}
	);

	my $done = Gtk2::Button->new_from_stock('gtk-done');
	$done->signal_connect('clicked' => 
		sub {
			print Dumper $recur->get_model;
		}
	);

=head1 METHODS

=head2 Gtk2::Ex::ICal::Recur->new()

Accepts no arguments. Returns the object.

=head2 Gtk2::Ex::ICal::Recur->set_model($model)

The C<model> is designed based on the the ICal spec. Please look at the 
C<DateTime::Event::ICal>. The structure of this hash is based on that module.

	my $model = {
		'dtstart' => { 
			year => 2000,
			month  => 6,
			day    => 20,
		},
		'count' => 17,
		'freq' => 'yearly',
		'interval' => '5',
		'byweekno' => [1, -1],
		'byday' => ['su','fr', 'mo'],
	};
	$recur->set_model($model);


=head2 Gtk2::Ex::ICal::Recur->get_model()

Returns a C<model> as described in the section above.

=head2 Gtk2::Ex::ICal::Recur->update_preview()

This method retrieves the model and sends it to an instance of C<DateTime::Event::ICal>
internally and gets a list of dates. The list is then displayed in a listview.

=head1 AUTHOR

Ofey Aikon, C<< <ofey.aikon at gmail dot com> >>

=head1 BUGS

You tell me. Send me an email !

=head1 ACKNOWLEDGEMENTS

To the wonderful gtk-perl-list.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Ofey Aikon, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under 
the terms of the GNU Library General Public License as published by the 
Free Software Foundation; 

This library is distributed in the hope that it will be useful, but WITHOUT ANY 
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
PARTICULAR PURPOSE. See the GNU Library General Public License for more details.

You should have received a copy of the GNU Library General Public License along 
with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307 USA.

=head1 SEE ALSO

DateTime::Event::ICal

=cut
