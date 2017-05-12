#
# Finance::QuoteOptions Module
# Extract options prices and series information from the web.
#
# (C) Copyright 2007-2010 Kirk Bocek
# Version 0.20 Contributions by Dan Dascalescu
#
package Finance::QuoteOptions;

#require 5.6.1;
use 5.006001;
use strict;
use WWW::Mechanize;
#use LWP::UserAgent; #See Changes document
use HTML::TokeParser;

# set the version for version checking
our $VERSION = 0.23;

############################
# Start of class definitions
############################

sub new {
    my $class = shift;
    my $self  = {};
    $self->{source} = 'yahoo';
    $self->{symbol} = undef;
    $self->{proxy} = undef;

    $self->{symbol} = shift if @_; #Set symbol if provided
    $self->{symbol} = uc $self->{symbol} if $self->{symbol};

    bless ($self, $class);
    return $self;
}

sub symbol {
    #Set or return target symbol
    my $self = shift;
    if (not @_) {
        return $self->{symbol};
    }
    $self->{symbol} = shift;
    $self->{data}  = [];
    $self->{success} = undef;
    $self->{status} = undef;
    $self->{response} = undef;
}

sub source {
    #Set or return data source
    #Only 'yahoo' or 'cboe' is accepted
    #Set source to 'yahoo' if anything else is provided
    my $self = shift;

    return $self->{source} unless @_;

    my $param = shift;
    $self->{source} = 'yahoo';
    $self->{source} = 'cboe' if lc($param) eq 'cboe';
    return $self->{source};
}

sub retrieve {
    #get data
    my ($self, $expirations) = @_;
    return 0 unless $self->{symbol};
    if ($self->{source} eq 'cboe') {
        $self->getcboedata();
    } else {
        #Yahoo is the default
        $self->getyahoodata($expirations);
    }
    return $self->{success};
}

sub expirations {
    #Return arrayref of all expiration dates
    my $self = shift;
    my $dates = [];
    push @$dates, $_->{exp} foreach @{$self->{data}};
    return $dates;
}

sub calls {
    #Return arrayref with all calls for a given expiration
    #If param is 6 or 8 characters then it's an expiration date
    #3 or fewer characters and it's number of expirations out
    #Date can be ###, YYYYMM or YYYYMMDD
    my $self = shift;
    my $exp = shift;
    return if not defined $exp or $exp < 0;
    #Check if too many expirations out:
    return if length($exp) < 4 and $exp > $#{$self->{data}};
    #If not number of exp out, then param must be 6 or 8 chars long
    return if length($exp) > 3 and length($exp) !~ /^[68]$/;

    $exp += 0; #Make sure it's numeric
    return $self->{data}->[$exp]->{calls} if length $exp < 4;
    #Param is date
    foreach (@{$self->{data}}) {
        return $_->{calls} if length $exp == 6 and $exp == substr($_->{exp},0,6);
        return $_->{calls} if length $exp == 8 and $exp == $_->{exp};
    }
    return;
}

sub puts {
    #Return all puts for a given expiration
    #See calls() above
    my $self = shift;
    my $exp = shift;
    return if not defined $exp or $exp < 0;
    return if length($exp) < 4 and $exp > $#{$self->{data}};
    return if length($exp) > 3 and length($exp) !~ /^[68]$/;

    $exp += 0; #Make sure it's numeric
    return $self->{data}->[$exp]->{puts} if length $exp < 4;
    foreach (@{$self->{data}}) {
        return $_->{puts} if length $exp == 6 and $exp == substr($_->{exp},0,6);
        return $_->{puts} if length $exp == 8 and $exp == $_->{exp};
    }
    return;
}

sub callsymbols {
    #Return arrayref with all call symbols for a given expiration
    my $self = shift;
    my $exp = shift;
    return if $exp < 0;
    return unless defined $exp and $exp <= $#{$self->data};
    $exp+=0;

    my $ret = [];
    push @$ret, $_->{symbol} foreach @{$self->{data}->[$exp]->{calls}};
    return $ret;
}

sub putsymbols {
    #Return arrayref with all put symbols for a given expiration
    my $self = shift;
    my $exp = shift;
    return if $exp < 0;
    return unless defined $exp and $exp <= $#{$self->data};
    $exp+=0;

    my $ret = [];
    push @$ret, $_->{symbol} foreach @{$self->{data}->[$exp]->{puts}};
    return $ret;
}

sub callstrikes {
    #Return arrayref with all call strike prices for a given expiration
    my $self = shift;
    my $exp = shift;
    return if $exp < 0;
    return unless defined $exp and $exp <= $#{$self->data};
    $exp+=0;

    my $ret = [];
    push @$ret, $_->{strike} foreach @{$self->{data}->[$exp]->{calls}};
    return $ret;
}

sub putstrikes {
    #Return arrayref with all put strike prices for a given expiration
    my $self = shift;
    my $exp = shift;
    return if $exp < 0;
    return unless defined $exp and $exp <= $#{$self->data};
    $exp+=0;

    my $ret = [];
    push @$ret, $_->{strike} foreach @{$self->{data}->[$exp]->{puts}};
    return $ret;
}

#-------------------------------------------------------------------
sub option {
    #Retrieve a single option
    my $self = shift;
    my $sym = shift;
    return unless $sym;

    my $ret = undef;
    my $date = undef;
    my $opt = undef;
    MAIN: for my $exp (@{$self->{data}}) {
        $date = $exp->{exp};
        for my $o (@{$exp->{calls}}) {
            if (lc $o->{symbol} eq lc $sym) {
                $opt = $o;
                last MAIN;
            }
        }
        for my $o (@{$exp->{puts}}) {
            if (lc $o->{symbol} eq lc $sym) {
                $opt = $o;
                last MAIN;
            }
        }
    }
    #Copy the found option to a new annonymous hash
    #Since we need to add the {exp} key
    if ($opt) {
        $ret = {};
        %$ret = %$opt;
        $ret->{exp} = $date;
    }
    return $ret;
}

sub success {
    #Set or retrieve success
    my $self = shift;
    my $stat = shift;
    if (defined $stat) {
        $self->{success} = $stat;
    }
    return $self->{success};
}

sub status {
    #Set or retrieve status
    my $self = shift;
    my $stat = shift;
    $self->{status} = $stat if defined $stat;
    return $self->{status};
}

sub response {
    #Set or retrieve response
    my $self = shift;
    my $stat = shift;
    $self->{response} = $stat if defined $stat;
    return $self->{response};
}

sub proxy {
    #Set or retrieve proxy setting
    my $self = shift;
    my $stat = shift;
    $self->{proxy} = $stat if defined $stat;
    return $self->{proxy};
}

sub data {
    #Return reference to data hash
    my $self = shift;
    return $self->{data};
}

sub version {
    #Return version number
    my $self = shift;
    return $VERSION;
}

#-------------------------------------------------------------------
sub getyahoodata {
    #
    # Main query page:
    # http://finance.yahoo.com/q/op?s=DIA
    # Additional expirations:
    # http://finance.yahoo.com/q/op?s=DIA&m=2007-06
    #
    # The main query page yields options for only the next expiration.
    # At the top of those tables is a list of other expiration months.
    # Generate the URLs for those additional pages and visit them
    # in turn to get all the options data.
    #
    my $self = shift;
    my $expirations = shift || -1;  # how many expirations to retrieve, < 0 means all
    my $q = LWP::UserAgent->new(
        agent => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
        timeout => 60,
    );

    #Set proxy if user has provided one
    $q->proxy(['http'], $self->proxy) if $self->proxy;

    return unless $self->symbol;
    my $sym = uc $self->symbol;

    my $response = $q->get("http://finance.yahoo.com/q/op?s=$sym");
    #Copy the LWP status to this instance
    $self->{success} = $response && $response->is_success;
    return unless $self->{success};
    $self->{response} = $response;
    $self->{status} = $response->code;
    my $content = $response->content;
    return if $content =~ /there are no all markets results for/i;  # MDER.PK


    my $tnum;
    my $st = HTML::TokeParser->new(\$content);
    my $ret;
    my $text;
    local ($_,$1,$2,$3,$4,$5); #Localizing special variables is recommended under mod_perl

    #
    # First look at the DIV tags to find 'View By Expiration'. Parse out
    # the list of expiration months. Create @optmonths containing expiration
    # months. Main loop will pop these off one by one, retrieve that page
    # and add the data to the data object.
    #

    my %month2num = qw(jan 01 feb 02 mar 03 apr 04 may 05 jun 06
        jul 07 aug 08 sep 09 oct 10 nov 11 dec 12);
    my %lmonth2num = qw(january 01 february 02 march 03 april 04 may 05 june 06
        july 07 august 08 september 09 october 10 november 11 december 12);
    my @optmonths = ('start');
    #Hash to translate Yahoo's column headers to our standard hash keys
    my %xheaders = (
        strike => 'strike',
        symbol => 'symbol',
        bid => 'bid',
        ask => 'ask',
        last => 'last',
        vol => 'volume',
        open_int => 'open',
        chg => 'change'
    );

    my $expdate = '';
    # @{$calldata} and @{$putdata} are arrays of hashes
    my $calldata = [];
    my $putdata = [];

    MAIN: while (@optmonths and $expirations) {  # keeps looping if $expirations was -1
        if ($optmonths[0] eq 'start') {
            #First time here, we're on the main query page. Extract expirations
            #months and populate @optmonths
            $expirations--;
            GETEXP: while ($st->get_tag('div')) {
                $text=$st->get_trimmed_text('/div');
                if ($text =~ /view by expiration/i) {
                    #Get expiration months
                    my ($exp) = $text =~ /view by expiration(.*)call options/i;
                    @optmonths = split(/\|/,$exp);
                    #Convert 'Jan 01' format to 'YYYY-MM'
					#Yahoo uses *both* short 'Jan' and long 'January'
                    for (@optmonths) {
                        last unless /(\w{3,9})\s+(\d{2,4})/;
						if (length($1) == 3) {
							#short month name or May
                        	$_ = ($2 < 100 ? 2000+$2 : $2) . '-' . $month2num{lc $1};
						} else {
							#long month name
                        	$_ = ($2 < 100 ? 2000+$2 : $2) . '-' . $lmonth2num{lc $1};
						}
                    };
                    shift @optmonths; #The first month is the page we're already at
                    last GETEXP;
                }
            }
        } else {
            #@optmonths has been populated, shift off the next month
            #and retrieve that page. When @optmonths is empty, we're done.
            #Additional months are at http://finance.yahoo.com/q/op?s=DIA&m=2007-06
            my $month = shift @optmonths;
            $expirations--;
            $response = $q->get("http://finance.yahoo.com/q/op?s=$sym&m=$month");
            $expdate = '';
            #Copy the LWP status to this instance
            $self->{success} = $response->is_success;
            $self->{status} = $response->code;
            $self->{response} = $response;
            next MAIN unless $self->{success};
        }

        # There's something like 25 or 26 tables present. We're only looking for
        # four of them: the Calls header and data tables and the Puts header
        # and data tables.
        #
        # We'll use HTML::TokeParser's ability to go from <tr> tag to <tr> tag
        # even though the rows might be in different tables.
        # This requires a specific order of tables: calls header then
        # calls data then puts header then puts data.
        #
        # Look at the first TD cell in a table to determine if it's one we want:
        # 'Call Options' is the header table for calls and
        # 'Put Options' is the header table for puts. The *next* table after the
        # header table that starts with 'Strike' is the data table for that
        # category. Use $mode to tell which table we're currently looking for.

        #Reset the TokeParser object so we can scan by tables
        $content = $response->content;
        $st = HTML::TokeParser->new(\$content);
        my ($tag,$newrow,$colcnt) = ('',0,0);
        my @callheaders = ();
        my @putheaders = ();
        $calldata = [];
        $putdata = [];

        $st->get_tag('table'); #Jump to first table
        my $mode='start';
        ROW: while ($tag=$st->get_tag('tr','/table','/html')) {
            #TokeParser returns arrayref if found, undef if no more tags
            $tag = $tag->[0];
            last MAIN if $tag =~ /\/html/i or not $tag;
            #Finished when getting put data but found end of table
            #Some options pages (e.g. CENTA) have no Puts, just the header line
            last ROW if $tag =~ /\/table/i and $mode =~ /gputdata/;
            #First loop: Getting Rows
            $newrow=1;
            CELL: while ($tag=$st->get_tag('th', 'td','/tr','/html')) {
                #Second loop: getting table cells
				#As of 2010-08-31 Yahoo using <th> tags
                my $in_the_money = 0+ (ref $tag->[1] && 
					exists $tag->[1]->{class} && $tag->[1]->{class} eq 'yfnc_h');
                $tag = $tag->[0];

                last MAIN if $tag =~ /\/html/i; #No data returned
                last CELL if $tag =~ /\/tr/i; #last cell in row
                $text=$st->get_trimmed_text('/th', '/td');

                #Perform cleanup & set mode between new rows
                if ($newrow) {
                    if ($mode =~ /start|gcalldata/ and
                            $text =~ /call options|put options/i) {
                        #Found Header Table
                        $mode='gcalldate' if $text =~ /call options/i;
                        $mode='gputdate' if $text =~ /put options/i;
                        $newrow=0;
                        next CELL;
                    } elsif ($mode eq 'gcalldate') {
                        #Got the expiration date in the call header
                        $mode = 'gcallheaders';
                        next ROW;
                    } elsif ($mode eq 'gputdate') {
                        #Got the expiration date in the put header
                        $mode = 'gputheaders';
                        next ROW;
                    } elsif (($mode eq 'gcallheaders' and not @callheaders) or
                            ($mode eq 'gputheaders' and not @putheaders)) {
                        #Haven't found column headers yet
                        next ROW unless $text =~ /strike/i;
                    } elsif ($mode eq 'gcalldata' or
                            ($mode eq 'gcallheaders' and @callheaders)) {
                        #Have column headers
                        next ROW unless $text; #Nothing in first cell
                        #Add a new row to @{$calldata}
                        push @{$calldata}, {in_the_money => $in_the_money};

                        $mode='gcalldata';
                        $colcnt=0;
                    } elsif ($mode eq 'gputdata' or
                            ($mode eq 'gputheaders' and @putheaders)) {
                        #Have column headers
                        #Add a new row to @{$putdata}
                        push @{$putdata}, {in_the_money => $in_the_money};
                        $mode = 'gputdata';
                        $colcnt=0;
                    } else {
                        #Nothing we want in this row
                        next ROW;
                    }
                }
                $newrow = 0;

                #Extract the data
                if ($mode =~ /gcalldate|gputdate/) {
                    if ($text and not $expdate) {
                        #Extract expiration date, convert to YYYYMMDD
						#Text Looks like Expire at close Friday, September 17, 2010
                        #$text =~ /(\w{3})\s+(\d{1,2}),\s+(\d{4})/;
                        $text =~ /(\w{3,9})\s+(\d{1,2}),\s+(\d{4})/;
						if (length($1) == 3) {
							#short month name or May
                        	$expdate = $3 . $month2num{lc $1} . $2;
						} else {
							#long month name
                        	$expdate = $3 . $lmonth2num{lc $1} . $2;
						}
                    }
                    $mode = 'gcallheaders' if $mode eq 'gcalldate';
                    $mode = 'gputheaders' if $mode eq 'gputdate';
                } elsif ($mode =~ /gcallheaders|gputheaders/) {
                    #Extract table headers
                    #Use %xheaders to translate to our standard headers
                    $text =~ s/ /_/g; #Spaces to underscores
                    push @callheaders, $xheaders{lc($text)}
                        if $mode eq 'gcallheaders';
                    push @putheaders, $xheaders{lc($text)}
                        if $mode eq 'gputheaders';
                } elsif ($mode =~ /gcalldata|gputdata/) {
                    #cleanup $text
                    $text =~ s/,//g; #Remove commas
                    if ($text =~ /(up|down)\s+(\d*.?\d*)/i) {
                        #This is the Chg column
                        #Convert 'Up/Down' to + or -
                        $text = $2;
                        $text*=-1 if $1=~/down/i;
                    }
                    #Insert the data
                    #Remove the '.X' Yahoo appends to symbol
                    if ($mode eq 'gcalldata') {
                        $calldata->[-1]->{$callheaders[$colcnt]} = $text;
                    #    $calldata->[-1]->{symbol} =~ s/\.X$//i
                    #        if $callheaders[$colcnt] eq 'symbol';
                    } else {
                        $putdata->[-1]->{$putheaders[$colcnt]} = $text;
                    #    $putdata->[-1]->{symbol} =~ s/\.X$//i
                    #        if $putheaders[$colcnt] eq 'symbol';
                    }
                    $colcnt++;
                }
            } #Getting TD
        } #Getting TR

        #Sort calls and puts by strike price
        if (not exists $calldata->[0]->{symbol}) {
            # if the option has no calls, empty the array
            $calldata = [];
        }
        if (not exists $putdata->[0]->{symbol}) {
            # if the option has no puts (e.g. CENTA as of 2009-Feb-15), empty the array
            $putdata = [];
        }
        @{$calldata} = sort { $a->{strike} <=> $b->{strike} } @{$calldata};
        @{$putdata} = sort { $a->{strike} <=> $b->{strike} } @{$putdata};

        #If this expiration already exists in $self->{data}, append
        #new data and resort, otherwise create new expiration
        CHECKDUP: {
            foreach (@{$self->{data}}) {
                if ($_->{exp} == $expdate) {
                    #Duplicate present
                    @{$_->{calls}} = sort { $a->{strike} <=> $b->{strike} }
                        (@{$_->{calls}}, @{$calldata});
                    @{$_->{puts}} = sort { $a->{strike} <=> $b->{strike} }
                        (@{$_->{puts}}, @{$putdata});
                    last CHECKDUP; #Don't add new expiration
                } #Duplicate expiration already present
            }
            #Add new expiration
            #Only executed if no duplicates expirations present
            push @{$self->{data}}, {
                exp => $expdate,
                calls => $calldata,
                puts => $putdata
            };
        }

        #Sort data by expirations
        @{$self->{data}} = sort { $a->{exp} <=> $b->{exp} } @{$self->{data}};

    } #End MAIN loop

} #End getyahoodata

#-------------------------------------------------------------------
sub getcboedata {
    require WWW::Mechanize;
    #
    # Main query page:
    # http://www.cboe.com/DelayedQuote/QuoteTable.aspx
    #
    # Get expirations from
    # http://www.cboe.com/DelayedQuote/SimpleQuote.aspx?ticker=BQQ+OH-E
    #
    # Unlike Yahoo, the main query page has *all* the options available.
    # Alas, it is lacking the expiration dates for those options.
    # We'll drill down into the individual option page to get the date.
    #
    # Right now we only do this once for each 'YY MMM' format date found
    # in the option description on the first page. We *assume* that all
    # subsequent dates of the same format have the *same* full date.
    #
    my $self = shift;
    my $q = WWW::Mechanize->new(autocheck => 0);
    $q->agent_alias('Linux Mozilla');
    $q->quiet(1);
    $q->timeout(60);
    #Set proxy if user has provided one
    $q->proxy(['http', 'ftp'], $self->proxy) if $self->proxy;

    return unless $self->symbol;
    my $sym = uc $self->symbol;

    #Hash to translate CBOE column headers to our standard hash keys
    my %xheaders = (
        bid => 'bid',
        ask => 'ask',
        last_sale => 'last',
        vol => 'volume',
        open_int => 'open',
        net => 'change'
    );

    $q->get("http://www.cboe.com/DelayedQuote/QuoteTable.aspx");
    return unless $q->success;
    $q->submit_form(
        fields    => { 'ucQuoteTableCtl:txtSymbol'  => $sym,
                'ucQuoteTableCtl:ALL' => 2 },
        button    => 'ucQuoteTableCtl:btnSubmit'
    );
    #Copy the WWW::Mechanize status to this instance
    $self->{success} = $q->success;
    $self->{status} = $q->status;
    $self->{response} = $q->response;

    return unless $q->success;

    # Output from mech-dump to get labels above:
    #  ucQuoteTableCtl:txtSymbol=     (text)
    #  ucQuoteTableCtl:chkAllExchange=<UNDEF> (checkbox)
    #    [*<UNDEF>/off|on/All exchange option quotes (if multiply listed)]
    #  ucQuoteTableCtl:ALL=0          (radio)
    #    [*0/List near term at-the-money options & Weeklys if avail.|
    #    2/List all options, LEAPS & Weeklys if avail. (Single page)]
    #  ucQuoteTableCtl:btnSubmit=Submit (submit)

    my $tnum;
    my $st = HTML::TokeParser->new(\$q->{content});
    my $ret;
    my ($tag,$text,$colcnt) = ('','',0);
    local ($_,$1,$2,$3,$4,$5); #Localizing special variables is recommended under mod_perl

    my @optmonths = ();
    my %months2num = qw(jan 01 feb 02 mar 03 apr 04 may 05 jun 06
        jul 07 aug 08 sep 09 oct 10 nov 11 dec 12);
    my @callheaders = ();
    my @putheaders = ();
    my $putscol = 0; #Column where puts data starts

    $st->get_tag('table'); #Jump to first table
    #Find start of data:
    HEADER: while ($st->get_tag('tr')) {
        $st->get_tag('td');
        if ($st->get_trimmed_text('/td') =~ /calls/i) {
            #Parse out the column headers
            my $mode='calls';
            while (my $tag=$st->get_tag('td','/tr')) {
                #get_tag returns undef when no more tags
                $tag=@{$tag}[0];
                last HEADER if $tag =~ /\/tr/i;
                my $text = $st->get_trimmed_text('/td');
                $text =~ s/ /_/g; #spaces to underscores
                if ($text =~ /puts/i) {
                    $mode = 'puts';
                    next;
                }
                if ($mode eq 'calls') {
                    push @callheaders,$xheaders{lc $text};
                } else {
                    push @putheaders,$xheaders{lc $text};
                }
            }
            last HEADER;
        }
    }

    #Unlike Yahoo, the main page does not have the actual
    #expiration date on it, just the YYMMM version. We are
    #going to *assume* that all YYMMM expirations are the
    #*same* actual date. The first time we hit a YYMMM date,
    #drill down into the details for that option to extract
    #the actual date and then use it for all subsequent
    #YYMMM options.
    #So, there might be a problem if there are weeklys,
    #monthlies or quarterlies present...
    #http://www.cboe.com/micro/weeklys/introduction.aspx
    my %expirations = ();
    my %tempdata = ();

    no warnings;
    ROW: while ($tag=$st->get_tag('tr','/table')) {
        #get_tag returns undef when no more tags
        $tag=@{$tag}[0];
        last ROW if $tag =~ /\/table/;
        my $mode = 'start';
        my @tmpheaders = @callheaders;
        my $call = {};
        my $put = {};
        my $exp = '';
        CELL: while ($tag=$st->get_tag('td','/tr')) {
            $tag=@{$tag}[0];
            last CELL if $tag =~ /\/tr/i;
            $text=$st->get_trimmed_text('/td');
            next ROW if $text =~ /\[img\]/i; #There's an IMG after the column headers

            #Description looks like "07 May 57.00 (IWT EE-E)"
            if ($mode eq 'start' and
                $text =~ /(\d{2} \w{3}) (\d{1,5}\.\d{2}) \((\w{1,4}) (\w{2})-(\w)\)/) {
                #Found call description
                $exp = $1;
                $call->{strike} = $2;
                $call->{symbol} = "$3$4";
                my $linksym = "$3+$4";
                my $type = $5;
                $exp =~ s/ //g; #Back-referencing variables reset on any regex

                #Check if expiration date has already been found, if not
                #drill down to option detail page to get it
                unless ($expirations{$exp}) {
                    my $det = WWW::Mechanize->new();
                    $det->agent_alias('Linux Mozilla');
                    $det->quiet(1);
                    $det->get("http://www.cboe.com/DelayedQuote/SimpleQuote.aspx?ticker=$linksym-$type");
                    #Copy the WWW::Mechanize status to this instance
                    $self->{success} = $det->success;
                    $self->{status} = $det->status;
                    $self->{response} = $det->response;
                    my $dat = HTML::TokeParser->new(\$det->{content});
                    unless ($self->{success}) {
                        #Detail lookup failed. IP address probably blacklisted
                        #Manually calc 3rd Friday of month
                        my ($tyear,$tmon) = $exp =~ /(\d{2})(\w{3})/;
                        $tyear += 2000;
                        $tmon = lc $tmon;
                        my %mon2digit = qw/jan 01 feb 02 mar 03 apr 04 may 05
                            jun 06 jul 07 aug 08 sep 09 oct 10 nov 11 dec 12/;
                        use Date::Calc;
                        #DOW is 5 for Friday, 3rd occurance
                        my ($year,$month,$day) =
                            Date::Calc::Nth_Weekday_of_Month_Year($tyear,$mon2digit{$tmon},5,3);
                        #Pad zeros to month and day
                        $month = substr(100+$month,-2);
                        $day = substr(100+$day,-2);
                        $expirations{$exp} = "$year$month$day";
                    } else {
                        #Extract date from option detail page
                        DATETABLE: while (my $tag=$dat->get_tag('table', '/table')) {
                            $tag=@{$tag}[0];
                            next DATETABLE if $tag =~ /\/table/i;
                            my $text=$dat->get_trimmed_text('/table');
                            if ($text =~ /expiration date\s*(\d{2})\/(\d{2})\/(\d{4})/i) {
                                $expirations{$exp} = "$3$1$2";
                                last DATETABLE;
                            }
                        }
                    }
                }

                $mode = 'call';
            } elsif ($mode eq 'call' and
                $text =~ /(\d{2} \w{3}) (\d{1,5}\.\d{2}) \((\w{1,4}) (\w{2})-\w\)/) {
                #Found put description
                $exp = $1 unless $exp; #Should have found it with call
                $put->{strike} = $2;
                $put->{symbol} = "$3$4";
                $exp =~ s/ //g; #Back-referencing variables reset on any regex

                $mode = 'put';
                @tmpheaders = @putheaders;
            } elsif ($mode eq 'call') {
                $call->{shift @tmpheaders} = $text;
            } elsif ($mode eq 'put') {
                $put->{shift @tmpheaders} = $text;
            } else {
                #This should never happen
                #print "ERROR parsing CBOE data!!!!\nText: $text\n";
            }
        } #Get TD

        #Move put and call to proper location using $exp
        unless ($tempdata{$exp}->{exp}) {
            #Create new expiration in %tempdata
            $tempdata{$exp}->{exp} = $expirations{$exp};
            $tempdata{$exp}->{calls} = [];
            $tempdata{$exp}->{puts} = [];
        }
        #Move hashrefs into %tempdata
        push @{$tempdata{$exp}->{calls}},$call;
        push @{$tempdata{$exp}->{puts}},$put;

    } #Get TR

    #Sort %tempdata by expiration dates and move into @{$self->{data}}
    push @{$self->{data}}, $tempdata{$_} for
        sort { $tempdata{$a}->{exp} <=> $tempdata{$b}->{exp} }
        keys %tempdata;

    #Sort puts and calls at each expiration by strike price
    for (@{$self->{data}}) {
        @{$_->{calls}} =
            sort { $a->{strike} <=> $b->{strike} }  @{$_->{calls}};
        @{$_->{puts}} =
            sort { $a->{strike} <=> $b->{strike} }  @{$_->{puts}};
    }

} #End getcboedata

1;
__END__

=head1 NAME

Finance::QuoteOptions - Perl extension for retrieving options pricing and
series information from the web.

=head1 SYNOPSIS

  use Finance::QuoteOptions;
  my $q=Finance::QuoteOptions->new('DIA');
  die 'Retrieve Failed' unless $q->retrieve;

  #Expiration dates in ISO format (YYYYMMDD)
  my @expirations = @{$q->expirations};

  #Calls/Puts for next expiration, sorted by strike price
  my @calls = @{$q->calls(0)};
  my @puts = @{$q->puts(0)};

  #Data from an individual option
  my $strike = $q->option('XYZAB')->{strike};
  my $symbol = $q->option('XYZAB')->{symbol};
  my $bid = $q->option('XYZAB')->{bid};
  my $ask = $q->option('XYZAB')->{ask};

=head1 DESCRIPTION

A 'screen-scraper' utility using C<WWW::Mechanize> and C<HTML::TokeParser> to
retrieve and parse options information from either Yahoo Finance or the Chicago
Board Options Exchange (CBOE) web site. The CBOE probably has better data but
Yahoo is much faster. By default, Yahoo Finance is used as the source.

The Yahoo address used, using DIA as an example, is:
  http://finance.yahoo.com/q/op?s=DIA

The CBOE address used is:
  http://www.cboe.com/DelayedQuote/QuoteTable.aspx

=head2 CBOE Blacklist Warning

The CBOE site has two interfaces for retrieving option information: a page
where you can download a CSV file and a web page that displays an HTML table.
At the time of writing this module (2007-2008), there was a big warning not
to do any kind of automated retrieval of the CSV information. So I wrote this
module to use the web page, even though the CSV file would be I<so> simple
to process.

Unfortunately, although I could find no such warning on the web portion of the
CBOE site, I B<still> got blacklisted from using the web portion, after a
couple of weeks of using this code and tens of thousands of queries. I was
blacklisted on June 4, 2007. Sometime before February 2009 the blacklist was 
removed. However I assume the block would be replaced if this code is used
again.

As of February 2009, the HTML page also has the warning from the CSV page.

So if you're doing many queries, use Yahoo as your source. Yahoo is much faster
anyway. It does have less data than CBOE, but the only difference I've seen were
options with zero volume and open interest. Give it a try for 'KB'.


=head2 Methods

The following methods are available:

=over 4

=item my $q = Finance::QuoteOptions->new;

=item my $q = Finance::QuoteOptions->new('DIA');

The first version creates the new object but doesn't set the target symbol.
Use C<symbol()> to set the target symbol. The second version creates the new
object and sets the target symbol in one step.

=item source;

=item source('yahoo');

=item source('cboe');

Sets or retrieves the current data source. The default is Yahoo Finace.  Only
acceptable options are C<yahoo> and C<cboe>. Submitting anything else will set
the source to C<yahoo>.

Always returns currently selected source.

=item symbol;

=item symbol('DIA');

Sets or retrieves the target symbol for the query.

=item proxy;

=item proxy('http://proxy.example.com:8000/');

Sets or retrieves the proxy setting for the query. Set this before issuing a
retrieve command.

This is currently untested. If you are behind a proxy, please email the author
if you use this feature and let him know how it works.

=item retrieve;

=item retrieve(N);

Retrieves data from designated source, for N expiration dates starting from
now. Retrieves all available expiration dates if N is not specified. If you
are only interested in the upcoming expiration, call << $q->retrieve(1) >> as
this will be a few times faster.

Returns L<success()> value for last http access.

Note that L<success()> does I<not> indictate whether there are options
available for the queried stock. To make that determination, check
L<expirations()> after issuing a L<retrieve()> to see if any options have been
retrieved. For example:

  $q->retrieve;
  if (@{$q->expirations}) {
        #There are options
  } else {
        #There are no options
  }

=item expirations;

Returns arrayref of all expiration dates in the format YYYYMMDD sorted by date.

Returns C<undef> if not found.

=item calls(0);

=item calls(200705);

=item calls(20070518);

=item puts(0);

=item puts(200705);

=item puts(20070518);

Returns an arrayref containing all calls or puts for a given expiration,
sorted by strike price.

Returns C<undef> if expiration is not found.

Parameter can take three forms:

=over 4

=item * Number of Expirations Out

Parameter '0' is the next expiration, '1' is two expirations out and so on.

=item * Integer YYYYMM.

If there happen to be two expirations in the same month, only the first will be
returned. Use L<expirations()> to check for multiple expirations.  See L< Notes>
for more information about multiple expirations.

=item * Integer YYYYMMDD.

This specifies the exact expiration date.

=back

=item

The arrayref is an array of hashes containing all calls or puts for a given
expiration. The hashes referenced within the array look like:

   {
      strike => 000.00,
      symbol => 'ABCD',
      bid => 000.00,
      ask => 000.00,
      last => 000.00,
      open => 0000,
      volume => 0000,
      change => 0000,
      in_the_money => 1
   }

Returns C<undef> if not found. The in_the_money key is only found if using
Yahoo as a data source. It is not set when using the CBOE. in_the_money contains 
either 0 or 1.

=item callsymbols(0);

=item putsymbols(0);

Returns an arrayref of call or put symbols for a given expiration.  Parameter
is the number of expirations out starting from zero.

Returns C<undef> if not found.

=item callstrikes(0);

=item putstrikes(0);

Returns an arrayref of call or put strike prices for a given expiration.
Parameter is the number of expirations out starting from zero.

Returns C<undef> if not found.

=item option('ABCD');

Returns hashref with all of the data for a single option symbol. If a symbol
has somehow been duplicated, the nearest symbol by date will be returned.
Parameter is case-insensitive.

The hash has the same structure as C<calls()> or C<puts()> above with the
addition of a C<exp> key containing the expiration date.

Returns C<undef> if not found.

=item data()

Returns arrayref containing all data retrieved. See L<Internal Data Structure>
below.

=item success()

=item response()

=item status()

All three are directly copied from the C<WWW::Mechanize> object. See it's
documentation for more details. Retrieving full options data for a symbol
requires multiple http requests. Only the I<last> request will be reported
here.

C<success()> Returns a boolean telling whether the last request was successful.
If there hasn’t been an operation yet, returns false. This does I<not> indicate
if options are available for a stock. See L<retrieve()> above.

C<response()> Return the current response as an C<HTTP::Response> object.

C<status()> Returns the HTTP status code of the response.

=item version();

Returns Finance::QuoteOption version.

=back

=head2 Internal Data Structure

The methods provided will slice and dice the options data in various ways.
However, the data is maintained in a single data structure that can be directly
accessed. Yes, this is bad OO practice, but hey, I think someone once said
there's more than one way to do it.

Everything is stored in an arrayref retrieved by the L<data()> method. Each
array element is a hashref. Each referenced hash has the keys C<exp>, C<calls>
and C<puts>:

 @data (
   \%expiration1 {
      exp => YYYYMMDD,
      calls => \@calldata,
      puts => \@putdata
   },
   \%expiration2 {
      exp => YYYYMMDD,
      calls => \@calldata,
      puts => \@putdata
   },
   ...
 )

The arrays referenced by C<calls> and C<puts> are each arrays of hashrefs.  The
final hashes contain all the data for an individual option:

 @callorputdata (
   \%option1 {
      strike => 000.00,
      symbol => 'ABCD',
      bid => 000.00,
      ask => 000.00,
      last => 000.00,
      open => 0000,
      volume => 0000,
      change => 0000,
      in_the_money => 1
   },
   \%option2 {
      ...ditto...
   },
   ...
 )

So, to enumerate all available expiration dates:

 print $_->{exp},"\n" foreach @{$q->data};

Or to display the number of puts and calls along with the symbol and strike
price of the first and last call options of each expiration:

 foreach (@{$q->data}) {
   print "\n",$_->{exp},":\n";
   print 'Calls: ', scalar @{$_->{calls}},"\n";
   print 'Puts: ', scalar @{$_->{puts}},"\n";
   print 'First Call: ',  $_->{calls}->[0]->{symbol},
      " Strike $_->{calls}->[0]->{strike} \n";
   print 'Last Call: ',  $_->{calls}->[-1]->{symbol},
      " Strike $_->{calls}->[-1]->{strike} \n";
 }


=head2 Notes

C<WWW::Mechanize> and C<HTML::TokeParser> each have their own complex set of
dependencies. So be prepared for a wait if doing a CPAN install on a basic Perl
distribution.

Be sure to read L<CBOE Blacklist Warning>.

C<HTML::TokeParser>'s ability to jump from tag to tag should make this code
impervious to web page additions or changes which surround the actual options
information we're after. That is, as long as the structure of the tables
containing the basic information doesn't change.

The CBOE site is I<much> slower than Yahoo. In my testing Yahoo took about one
second to retrieve all options for a stock whereas the CBOE site took five to
fifteen seconds.

Because of the way the CBOE site is structured, there might be a problem if
there are options with more than one expiration date in a single month.  right
now, they'll all end up in the same expiration. I could fix this by drilling
down into the details for I<every> option but then the CBOE retrieval would get
even slower. So be careful if weeklys, monthlies or quarterlies are available
for a stock.  See L<http://www.cboe.com/micro/weeklys/introduction.aspx> for
more information.

Feel free to contact me at the address below if you have any questions,
problems or suggestions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<WWW::Mechanize>

L<LWP::UserAgent>

L<HTML::TokeParser>

L<Date::Calc>

L<http://www.perl.com/pub/a/2003/01/22/mechanize.html>

L<http://en.wikipedia.org/wiki/Screen_scraping>

=head1 AUTHOR

Kirk Bocek, E<lt>quoteoptions E<lt>ATE<gt> kbocek.comE<gt>

Version 0.20 contributions by Dan Descaleau,  E<lt>ddascalescu E<lt>ATE<gt> gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007,2008,2009 by Kirk Bocek

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.5 or, at your option,
any later version of Perl 5 you may have available.


=cut

