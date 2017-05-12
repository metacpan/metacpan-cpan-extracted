package Gantry::Plugins::Calendar;

use strict; 
use Gantry::Utils::HTML qw( :all );
use Gantry::Utils::Validate;
use Date::Calc qw(  Add_Delta_YMD 
                    Day_of_Week
                    Day_of_Week_Abbreviation
                    Day_of_Week_to_Text 
                    Days_in_Month 
                    Month_to_Text
                    check_date  );

use Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw(
    do_calendar_month
    calendar_month_js
);

############################################################
# Functions                                                #
############################################################
#-------------------------------------------------
# $site->do_calendar_month( $r, @p ) 
#-------------------------------------------------
sub do_calendar_month {
    my ( $site, $name, $year, $month ) = @_;
    
    my $chk = Gantry::Utils::Validate->new();
    
    $site->template_disable( 1 );

    $name   = ''                            if ( ! $chk->is_text( $name ) );
    $year   = ( 1900 + ( localtime() )[5] ) if ( ! $chk->is_number( $year ) );
    $month  = ( 1 + ( localtime() )[4] )    if ( ! $chk->is_number( $month ) );
    
    my @output = (
        '<html><head></head><body>',
        '<script type="text/javascript">',
        '<!--',
        '   window.focus(); ',
        '   function SendDate(d) { ',
        qq!     window.opener.SetDate("$name",d); window.close(); !,
        '   } ',
        '//--> ',
        '</script>',

        _calendar_month( 
            $site->r,
            ( $site->location . "/calendar_month/$name" ), 
            $month, 
            $year, 
            1, 
            \&_calendar_day 
        ),
        '</body></html>',
    );

    return( join "\n", @output );

} # END $site->do_calendar

#-------------------------------------------------
# _calendar_day( $year, $month, $day )
#-------------------------------------------------
sub _calendar_day {
    my ( $year, $month, $day ) = @_;

    return( ht_a(   'javascript://', "$day", 
                    "onClick=\"SendDate('$month-$day-$year')\"" ) );
} # END calendar_day

#-------------------------------------------------
# $site->calendar_month_js( $form_id )
#-------------------------------------------------
sub calendar_month_js {
    my( $site, $form_id ) = @_;
    
    # prepend document. to form_id id is not specified
    if ( $form_id !~ /^document\./i ) {
        $form_id = 'document.' . $form_id;
    }
    
    my $popup_url = $site->location . "/calendar_month/";   
    
    return( qq!
        <script type="text/javascript">
            function SetDate(field, date) {
                eval( '${form_id}.' + field + '.value = date;' );
            }
    
            function datepopup(name) { 
                window.open('$popup_url'+name, 'Shortcut',
                            'height=250,width=250' + 
                            ',screenX=' + (window.screenX+150) + 
                            ',screenY=' + (window.screenY+100) + 
                            ',scrollbars,resizable' );


            }
        </script>
    ! );

} # end: calendar_month_js

#-------------------------------------------------
# _calendar_month( $r, etc... )
#-------------------------------------------------
sub _calendar_month {
    my ( $r, $root, $month, $year, $select, $function, @params ) = @_;

    my $chk = Gantry::Utils::Validate->new();
    
    if ( ( ! $chk->is_integer( $month ) ) 
                || ( $month > 13 ) || ( $month < 1 ) ) {
        return( 'Malformed month.' );
    }

    if ( ( ! $chk->is_integer( $year ) ) || ( length( $year ) != 4) ) {
        return( 'Malformed year.' );
    }

    # Fix up some variables.
    my $month_max   = Days_in_Month( $year, $month ); 
    my $offset      = Day_of_Week( $year, $month, 1 );
    $offset         = ( $offset == 7 ) ? 0 : $offset;
    $root           =~ s/\/$//;

    my @lines = ht_table( { 'cols' => '7' } );

    if ( defined $select && $select ) {

        my ( $syear, $smonth ) = Add_Delta_YMD( $year, $month, 1, 0, -6, 0);

        # Build the month options.
        my @items;
        for my $option ( -6..6 ) {
            push( @items, "$syear/$smonth", Month_to_Text($smonth)." $syear" );

            ( $syear, $smonth ) = Add_Delta_YMD( $syear, $smonth, 1, 0, 1, 0);
        }

        # Push on the month select box.
        push(   @lines, 
                ht_form_js( $root ),
                ht_tr(),
                ht_td(  { class => 'head', align => 'center' },
                        ht_a(   ( ( ( $month - 1 ) < 1 ) ?
                                        "$root/". ( $year - 1 ). "/12" : 
                                        "$root/$year/" . ($month - 1)   ), 
                                '&lt;&lt;' ) ),

                ht_td(  { class => 'head', align => 'center', colspan => '5' },
                        ht_select(  'month', 1, "$year/$month", '', 
                                    qq!onChange="window.location = '$root/' !.
                                    q!+ month.options[month.selectedIndex].!.
                                    q!value;"!, @items ) ),


                ht_td(  { class => 'head', align => 'center' },
                        ht_a(   ( ( ( $month + 1 ) > 12 ) ?
                                        "$root/". ( $year + 1 ) . "/01" : 
                                        "$root/$year/" . ($month + 1) ), 
                                '&gt;&gt;' ) ),
                ht_utr(),
                ht_uform() );
    }
    else {
        push( @lines,   ht_tr(),
                        ht_td(  {   class => 'head',
                                    align => 'center', 
                                    colspan => '7' }, 
                                Month_to_Text( $month ) , " $year" ),
                        ht_utr() );
    }

    push( @lines,   ht_tr(),
                    ht_td(  { class => 'date', align => 'center' }, 
                            Day_of_Week_Abbreviation( 7 ) ) );

    for ( my $i = 1; $i < 7; $i++ ) {
        push( @lines,   ht_td(  { class => 'date', align => 'center' }, 
                                Day_of_Week_Abbreviation( $i ) ) );
    }   

    push( @lines, ht_utr() );

    my $extra   = ( ( ( $month_max % 7 ) + $offset ) > 7 ) ? 1 : 0 ;
    my $rows    = int( $month_max / 7 ) + $extra + 1;

    for ( my $i = 0; $i < $rows; $i++ ) {
        push( @lines, ht_tr() );

        for ( my $j = 1; $j < 8; $j++ ) {
            my $k =  $j + ( $i * 7 ) + ( $offset * -1 );

            if ( ( $k > 0 ) && ( $k < ( $month_max + 1 ) ) ) {
                push( @lines, ht_td( { class => 'day', align => 'center' },
                                    &$function( $year, $month, $k, @params )) );
            }
            else {
                push( @lines, ht_td( { class => 'day' }, '&nbsp;' ) );
            }
        }
        push( @lines, ht_utr() );
    }
    
    return( @lines, ht_utable() );
} # END _calendar_month

#-------------------------------------------------
# _cal_week( $r, etc... )
#-------------------------------------------------
# Draws one full week. $function is what you want
# it to do for each day in the week.
#-------------------------------------------------
sub _calendar_week {
    my ( $r, $root, $day, $month, $year, $function, @params ) = @_;

    my $chk = Gantry::Utils::Validate->new();
    
    # Validate our input.
    return( 'Malformed day.' )  if ( ! $chk->is_number( $day ) );
    return( 'Malformed month' ) if ( ! $chk->is_number( $month ) );
    return( 'Malformed year' )  if ( ! $chk->is_number( $year ) );
    return( 'Bad Date' )        if ( ! check_date( $year, $month, $day ) );

    # Figure some numbers out.
    my( $syear, $smonth, $sday ) = Add_Delta_YMD( $year, $month, $day, 0,0,-3);
    my( $eyear, $emonth, $eday ) = Add_Delta_YMD( $year, $month, $day, 0,0,3);
    my( $lyear, $lmonth, $lday ) = Add_Delta_YMD( $year, $month, $day, 0,0,-6);
    my( $gyear, $gmonth, $gday ) = Add_Delta_YMD( $year, $month, $day, 0,0,6);
    $root =~ s/\/$//;
    
    my @lines=( ht_table( {} ),
                ht_tr(),
    
                ht_td(  { class => 'head', align => 'center' },
                        ht_a( "$root/$lyear/$lmonth/$lday", '&lt;&lt;' ) ),

                ht_td(  { class => 'head', align => 'center', colspan => '5' },
                        qq!<SMALL><STRONG>$sday!,
                        Month_to_Text( $smonth ),
                        qq! $syear -- $eday !, 
                        Month_to_Text( $emonth ), qq! $eyear! ),

                ht_td(  { class => 'head', align => 'center' },
                        ht_a( "$root/$gyear/$gmonth/$gday", '&gt;&gt;' ) ),
                ht_utr(),
                ht_tr() );

    # Blammo, week headers.
    for ( -3..3 ) {
        my $wdt = Day_of_Week_to_Text( Day_of_Week( $syear, $smonth, $sday ) );

        push( @lines,   ht_td(  { class => 'head', align => 'center' },
                                qq!<SMALL><STRONG>$wdt</STRONG><BR>!,
                                qq!( $syear/$smonth/$sday )! ) );

        ( $syear, $smonth, $sday ) = 
                        Add_Delta_YMD( $syear, $smonth, $sday, 0, 0, 1);
    }
    
    push( @lines, ht_utr(), ht_tr() );

    # Put on the actual week days now.
    ( $syear, $smonth, $sday ) = Add_Delta_YMD( $year, $month, $day, 0, 0, -3);

    for ( -3..3 ) {
        push( @lines, ht_td( { class => 'day' },    
                             &$function( $syear, $smonth, $sday, @params ) ) );

        ( $syear, $smonth, $sday ) = 
                            Add_Delta_YMD( $syear, $smonth, $sday, 0, 0, 1);
    }

    return( @lines, ht_utr(), ht_utable() );
} # END _calendar_week

#-------------------------------------------------
# _calendar_year( $r, etc... )
#-------------------------------------------------
# Draws one full year. Function is what you want
# it to do for every day in the year.
#-------------------------------------------------
sub _calendar_year {
    my ( $r, $root, $year, $function, @params ) = @_;

    my $chk = Gantry::Utils::Validate->new();
    
    if ( ( ! $chk->is_number( $year ) ) || ( length( $year ) != 4 ) ) {
        return ( 'Malformed Year.' );
    }

    $root =~ s/\/$//;

    my @lines = (   ht_table( { 'cols' => '3' } ),
                    ht_tr(),
    
                    ht_td(  { align => 'left' },
                            ht_a( "$root/". ( $year - 1 ), '&lt;&lt;' ) ),

                    ht_td(  { align => 'center' },
                            qq!<BIG><STRONG>$year</STRONG></BIG>! ),

                    ht_td(  { align => 'right' },
                            ht_a( "$root/". ( $year + 1 ), '&gt;&gt;' ) ),

                    ht_utr(),
                    ht_tr() );

    for ( my $i = 0; $i < 12; $i++ ) {
        push( @lines, ht_utr(), ht_tr() ) if ( ( $i % 3 ) == 0 );

        # Put each month on.
        push( @lines,   ht_td(  { class => 'base',  valign => 'top' }, 
                                _calendat_month(    $r, $root, $i+1, $year, 0, 
                                            $function, @params ) ) );
    }
    
    return( @lines,
            ht_utr(),
            ht_tr(),

            ht_td(  { align => 'left' },
                    ht_a( "$root/". ( $year - 1 ), '&lt;&lt;' ) ),

            ht_td(  { align => 'center' },
                    qq!<big><strong>$year</strong</big>! ),
            
            ht_td(  { align => 'right' },
                    ht_a( "$root/". ( $year + 1 ), '&gt;&gt;' ) ),

            ht_utr(),
            ht_utable() );
} # END _calendar_year

# EOF
1;

__END__

=head1 NAME

Gantry::Plugins::Calendar - Calendar 

=head1 SYNOPSIS

    use Gantry::Plugins::Calendar;

or

    use Gantry qw/... Calendar/;

=head1 DESCRIPTION

If you have a date field on a web form, which the user must supply,
you can use this module to help them.  When you've got it set up,
your form will have a link sitting next to the date's text entry box.
If the user clicks the link, a calendar pops up.  It allows for
navigation by time period.  Each date is just linked text.  When the user
presses one of the links, that date is entered into the text field
as if they had typed it.

To make this happen do the following.

=over 4

=item 1.

Add Calendar to the list in the use statement for Gantry in your
application's base module.  For example:

    use Gantry qw/... Calendar/;

=item 2.

In your module's _form method, add the following to the form hash:

    javascript => $site->calendar_month_js( 'your_form_name' );

where your_form_name must match the name entry in the hash.

=item 3.

Add the following to the hash for your date fields:

    date_select => 'User Label',

User Label will be the link text, so make it something like 'Select'
or 'Choose Date'.

=back

That's all.

=head1 HOW IT WORKS

The three steps above are simple, but they conceal quite a bit of careful
Perl and Javascript code.  This section explains what is actually
happening behind the scenes.

When you use the Calendar template, methods are exported into the site
object.  The important ones are calendar_month_js and do_calendar_month.
The global handler will call do_calendar_month for you.

calendar_month_js creates two Javascript functions:

=over 4

=item datepopup(form_name)

makes the calendar window popup.

=item SetDate(field_name, date)

sets the date when the user clicks on a date in the popup window.

=back

You must pass the name of the form to calendar_month_js, otherwise
its Javascript won't be able to tell the name to the popup window,
which will then be unable to set any dates on your form.

do_calendar_month is the method called by the handler when the window
pops up.  It generates the calendar and manages user interaction with
it.  It relies on the internal _calendar_month to make the actual
output.  When the user clicks on a date, its Javascript first
calls SetDate with the field name and the date value
and then closes the popup window.

=head1 FUNCTIONS 

The other functions are not directly useful to normal callers
but here is a complete list.

=head2 Method you call

=over 4

=item calendar_month_js

See above.

=back

=head2 Methods called by global handler

=over 4

=item do_calendar_month( $site, ... )

This is the only do_* method we currently use.

=item do_calendar_week( $site ... )

Might not work, not tested.  Meant to display weeks with time slots.

=item do_calendar_year( $site ... )

Might not work, not tested.  Meant to display a whole year at a time.

=back

=head2 Functions used internatlly

=over 4

=item @month = _calendar_month( $r, $root, $month, $year, $select, \&function, @param )

This function creates a month in html for display. C<$r> is the apache
request object. C<$root> is the uri root of the calendar, this is used
for paging. C<$month> and C<$year> are the month and year to show.
C<$select> should be a boolean value, true if the month select is to be
shown, false otherwise. C<\&function> is a function referenc for the
day. C<@params> are any params that need to be passed to C<\&function>

=item @week = _calendar_week( $r, $root, $day, $month, $year, \&function, @param )

This function creates a week in html for display. C<$r> is the apache
request object. C<$root> is the uri root of the week, this is used for
paging. C<$day>, C<$month>, and C<$year> are the day, month, and year of
the Wednesday of the week. C<\&function> should be a function reference
for the day function. C<@param> is for the parameters for the day
function that will be passed through.

=item @year = _calendar_year( $r, $root, $year, \&function, @param )

This function creates a year in html for display. C<$r> is the apache
request object. C<$root> is the uri root of the year, this is used for
paging. C<$year> is the year to show. C<\&function> is the day function
to be used. C<@param> are any other params to pass into the day
function. This function uses the cal_month function to create it's
month.

=item @day = \&function( $year, $month, $day, @params)

This is the "day function" it is not defined in this module at all. It
needs to be defined by the user. The function should take the year,
month, and day to show. It should also accept the C<@params> that would
be passed into the cal_* params.

=back

=head1 SEE ALSO

Gantry(3)

=head1 LIMITATIONS and BUGS

Only do_calendary_month has been tested, the other do_* methods are
unlikely to work.

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>
Phil Crow <philcrow2000@yahoo.com>
Nicholas Studt <nstudt@angrydwarf.org>

=head1 COPYRIGHT and LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
