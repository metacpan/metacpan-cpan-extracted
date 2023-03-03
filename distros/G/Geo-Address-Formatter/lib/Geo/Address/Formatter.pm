package Geo::Address::Formatter;
$Geo::Address::Formatter::VERSION = '1.994';
# ABSTRACT: take structured address data and format it according to the various global/country rules

use strict;
use warnings;
use feature qw(say);
use Clone qw(clone);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename qw(dirname);
use File::Find::Rule;
use Ref::Util qw(is_hashref);
use Scalar::Util qw(looks_like_number);
use Text::Hogan::Compiler;
use Try::Catch;
use YAML::XS qw(LoadFile);
use utf8;

my $THC = Text::Hogan::Compiler->new;

# optional params
my $show_warnings = 1;
my $debug         = 0;
my $only_address  = 0;


sub new {
    my ($class, %params) = @_;

    my $self      = {};
    my $conf_path = $params{conf_path} || die "no conf_path set";

    # optional params
    if ( defined($params{no_warnings}) && ($params{no_warnings})){
        $show_warnings  = 0;
    }
    $only_address  = (defined($params{only_address}) && $params{only_address}) // 0;
    $debug         = (defined($params{debug})        && $params{debug})        // 0;

    $self->{final_components} = undef;
    bless($self, $class);

    say STDERR "************* in Geo::Address::Formatter::new ***" if ($debug);
    
    if ($self->_read_configuration($conf_path)){
        return $self;
    }
    die 'unable to read configuration';
}

sub _read_configuration {
    my $self = shift;
    my $path = shift;

    return if (! -e $path);

    my @a_filenames = File::Find::Rule->file()->name('*.yaml')->in($path . '/countries');

    $self->{templates}          = {};
    $self->{component_aliases}  = {};
    $self->{component2type}     = {};
    $self->{ordered_components} = [];

    # read the config file(s)
    my $loaded = 0;
    foreach my $filename (sort @a_filenames) {
        try {
            my $rh_templates = LoadFile($filename);

            # if file 00-default.yaml defines 'DE' (Germany) and
            # file 01-germany.yaml does as well, then the second
            # occurance of the key overwrites the first.
            foreach (keys %$rh_templates) {
                $self->{templates}{$_} = $rh_templates->{$_};
            }
            $loaded = 1;
        } catch {
            warn "error parsing country configuration in $filename: $_";
        };
    }
    return if ($loaded == 0);

    # see if we can load the components
    try {
        say STDERR "loading components" if ($debug);
        my @c = LoadFile($path . '/components.yaml');

        if ($debug){
            say STDERR Dumper \@c;
        }

        foreach my $rh_c (@c) {
            if (defined($rh_c->{name})){
                if (defined($rh_c->{aliases})){
                    $self->{component_aliases}{$rh_c->{name}} = $rh_c->{aliases};
                } else {
                    $self->{component_aliases}{$rh_c->{name}} = [];
                }
            }
        }

        foreach my $rh_c (@c) {
            push(@{$self->{ordered_components}}, $rh_c->{name});
            $self->{component2type}->{$rh_c->{name}} = $rh_c->{name};

            if (defined($rh_c->{aliases})) {
                foreach my $alias (@{$rh_c->{aliases}}) {
                    push(@{$self->{ordered_components}}, $alias);
                    $self->{component2type}->{$alias} = $rh_c->{name};
                }
            }
        }
        if ($debug){
            say STDERR 'component_aliases';
            say STDERR Dumper $self->{component_aliases};
            say STDERR 'ordered_components';
            say STDERR Dumper $self->{ordered_components};
            say STDERR 'component2type';
            say STDERR Dumper $self->{component2type};
        }
    } catch {
        warn "error parsing component configuration: $_";
    };

    # get the county and state codes and country2lang conf
    my @conf_files = qw(county_codes state_codes country2lang);
    foreach my $cfile (@conf_files) {
        $self->{$cfile} = {};
        my $yfile = $path . '/' . $cfile . '.yaml';
        if (-e $yfile) {
            try {
                $self->{$cfile} = LoadFile($yfile);
            } catch {
                warn "error parsing $cfile configuration: $_";
            };
        }
    }

    # get the abbreviations
    my @abbrv_filenames = File::Find::Rule->file()->name('*.yaml')->in($path . '/abbreviations');

    # read the config files
    foreach my $abbrv_file (@abbrv_filenames) {
        try {
            if ($abbrv_file =~ m/\/(\w\w)\.yaml$/) {
                my $lang = $1;                   # two letter lang code like 'en'
                my $rh_c = LoadFile($abbrv_file);
                $self->{abbreviations}->{$lang} = $rh_c;
            }
        } catch {
            warn "error parsing abbrv configuration in $abbrv_file: $_";
        };
    }
    #say Dumper $self->{abbreviations};
    #say Dumper $self->{country2lang};
    return 1;
}


sub final_components {
    my $self = shift;
    if (defined($self->{final_components})) {
        return $self->{final_components};
    }
    warn 'final_components not yet set' if ($show_warnings);
    return;
}


sub format_address {
    my $self          = shift;
    my $rh_components = clone(shift) || return;
    my $rh_options    = shift        || {};

    # 1. make sure empty at the beginning
    $self->{final_components} = undef;    

    if ($debug){
        say STDERR "*** in format_address ***";
        say STDERR Dumper $rh_options;
        say STDERR Dumper $rh_components;
    }

    # 2. deal with the options

    # 2a. which country format will we use?
    #     might have been specified in options
    #     otherwise look at components
    my $cc = $rh_options->{country}
        || $self->_determine_country_code($rh_components)
        || '';

    if ($cc) {
        $rh_components->{country_code} = $cc;
        $self->_set_district_alias($cc);
    }

    # 2b. should we abbreviate?
    my $abbrv = $rh_options->{abbreviate} // 0;

    # 2c. was only_address set at the formatting level
    my $oa = $only_address;
    if (defined($rh_options->{only_address})){
        $oa = $rh_options->{only_address};
    }

    if ($debug){
        say STDERR "component_aliases";
        say STDERR Dumper $self->{component_aliases};
    }

    # done with the options

    # 3. set the aliases, unless this would overwrite something
    # need to do this in the right order (as defined in the components file)
    # For example:
    # both 'city_district' and 'suburb' are aliases of 'neighbourhood'
    # so which one should we use if both are present?
    # We should use the one defined first in the list

    my $rhh_p2a;
    foreach my $c (keys %$rh_components){

        # might not need an alias as it is a primary type
        next if (defined($self->{component_aliases}{$c}));

        # it is not a primary type
        # is there an alias?
        if (defined($self->{component2type}{$c})){
            my $ptype = $self->{component2type}{$c};
            # but is it already set?
            if (! defined($rh_components->{$ptype}) ){
                # no, we will set it later
                $rhh_p2a->{$ptype}{$c} = 1;

            }
        }
    }

    # now we know which primary types have aliases
    foreach my $ptype (keys %$rhh_p2a){
        # is there more than one?
        my @aliases = keys %{$rhh_p2a->{$ptype}};
        if (scalar @aliases == 1){
            $rh_components->{$ptype} = $rh_components->{$aliases[0]};
            next;  # we are done with this ptype
        }

        # if there is more than one we need to go through the list
        # so we do them in the right order
        foreach my $c (@{$self->{component_aliases}->{$ptype}}){
            if (defined($rh_components->{$c})){
                $rh_components->{$ptype} = $rh_components->{$c};
                last; # we are done with this ptype
            }
        }
    }

    if ($debug){
        say STDERR "after component_aliases applied";
        say STDERR Dumper $rh_components;
    }

    # 4. deal wtih terrible inputs
    $self->_sanity_cleaning($rh_components);
    if ($debug){
        say STDERR "after sanity_cleaning applied";
        say STDERR Dumper $rh_components;
    }

    # 5. determine the template
    my $template_text;
    my $rh_config = $self->{templates}{uc($cc)} || $self->{templates}{default};
    
    if (defined($rh_options->{address_template})) {
        $template_text = $rh_options->{address_template};
    }
    else {

        if (defined($rh_config->{address_template})) {
            $template_text = $rh_config->{address_template};
        } elsif (defined($self->{templates}{default}{address_template})) {
            $template_text = $self->{templates}{default}{address_template};
        }
    
        # do we have the minimal components for an address?
        # or should we instead use the fallback template?
        if (!$self->_minimal_components($rh_components)) {
            say STDERR "using fallback" if ($debug);
            if (defined($rh_config->{fallback_template})) {
                $template_text = $rh_config->{fallback_template};
            } elsif (defined($self->{templates}{default}{fallback_template})) {
                $template_text = $self->{templates}{default}{fallback_template};
            }
            # no fallback
        }

    }

    say STDERR 'template text: ' . $template_text if ($debug);

    # 6. clean up the components, possibly add codes
    $self->_fix_country($rh_components);
    if ($debug){
        say STDERR "after fix_country";
        say STDERR Dumper $rh_components;
    }

    $self->_apply_replacements($rh_components, $rh_config->{replace});
    if ($debug){
        say STDERR "after applying_replacements applied";
        say STDERR Dumper $rh_components;
    }
    $self->_add_state_code($rh_components);
    $self->_add_county_code($rh_components);
    if ($debug){
        say STDERR "after adding codes";
        say STDERR Dumper $rh_components;
    }

    # 7. add the attention, if needed
    if ($debug){
        say STDERR "object level only_address: $only_address";
        say STDERR "formatting level only_address: $oa";
    }

    if ($oa){
        if ($debug){
            say STDERR "not looking for unknown_components";
            say STDERR "only_address was specified";
        }
    }
    else {
        my $ra_unknown = $self->_find_unknown_components($rh_components);
        if ($debug){
            say STDERR "unknown_components:";
            say STDERR Dumper $ra_unknown;
        }
        if (scalar(@$ra_unknown)){
            $rh_components->{attention} =
                join(', ', map { $rh_components->{$_} } @$ra_unknown);
            if ($debug){
                say STDERR "putting unknown_components in 'attention'";
            }
        }
    }

    # 8. abbreviate, if needed
    if ($abbrv) {
        $rh_components = $self->_abbreviate($rh_components);
    }

    # 9. prepare the template
    $template_text = $self->_replace_template_lambdas($template_text);

    # 10. compiled the template
    my $compiled_template =
        $THC->compile($template_text, {'numeric_string_as_string' => 1});

    if ($debug){
        say STDERR "before _render_template";
        say STDERR Dumper $rh_components;
        say STDERR "template: ";
        say STDERR Dumper $compiled_template;
    }

    # 11. render the template
    my $text = $self->_render_template($compiled_template, $rh_components);
    if ($debug){
        say STDERR "text after _render_template $text";
    }

    # 11. postformatting
    $text = $self->_postformat($text, $rh_config->{postformat_replace});

    # 12. clean again
    $text = $self->_clean($text);

    # 13. set final components
    $self->{final_components} = $rh_components;

    # all done
    return $text;
}

# remove duplicates ("Berlin, Berlin"), do replacements and similar
sub _postformat {
    my $self = shift;
    my $text = shift;
    my $raa_rules = shift;

    if ($debug){
        say STDERR "entering _postformat: $text"
    }

    # remove duplicates
    my @before_pieces = split(/, /, $text);
    my %seen;
    my @after_pieces;
    foreach my $piece (@before_pieces) {
        $piece =~ s/^\s+//g;
        $seen{$piece}++;
        if (lc($piece) ne 'new york') {
            next if ($seen{$piece} > 1);
        }
        push(@after_pieces, $piece);
    }
    $text = join(', ', @after_pieces);

    # do any country specific rules
    foreach my $ra_fromto (@$raa_rules) {
        try {
            my $regexp = qr/$ra_fromto->[0]/;
            my $replacement = $ra_fromto->[1];

            # ultra hack to do substitution
            # limited to $1 and $2, should really be a while loop
            # doing every substitution

            if ($replacement =~ m/\$\d/) {
                if ($text =~ m/$regexp/) {
                    my $tmp1 = $1;
                    my $tmp2 = $2;
                    my $tmp3 = $3;
                    $replacement =~ s/\$1/$tmp1/;
                    $replacement =~ s/\$2/$tmp2/;
                    $replacement =~ s/\$3/$tmp3/;
                }
            }
            $text =~ s/$regexp/$replacement/;
        } catch {
            warn "invalid replacement: " . join(', ', @$ra_fromto);
        };
    }
    return $text;
}

sub _sanity_cleaning {
    my $self          = shift;
    my $rh_components = shift || return;

    # catch insane postcodes
    if (defined($rh_components->{'postcode'})) {
        if (length($rh_components->{'postcode'}) > 20) {
            delete $rh_components->{'postcode'};
        } elsif ($rh_components->{'postcode'} =~ m/\d+;\d+/) {
            # sometimes OSM has postcode ranges
            delete $rh_components->{'postcode'};
        } elsif ($rh_components->{'postcode'} =~ m/^(\d{5}),\d{5}/) {
            $rh_components->{'postcode'} = $1;
        }
    }

    # remove things that might be empty
    foreach my $c (keys %$rh_components) {
        # catch empty values
        if (!defined($rh_components->{$c})) {
            delete $rh_components->{$c};
        }
        # no chars
        elsif ($rh_components->{$c} !~ m/\w/) {
            delete $rh_components->{$c};
        }
        # catch values containing URLs
        elsif ($rh_components->{$c} =~ m|https?://|) {
            delete $rh_components->{$c};
        }
    }
    return;
}

sub _minimal_components {
    my $self                = shift;
    my $rh_components       = shift || return;
    my @required_components = qw(road postcode); #FIXME - should be in conf
    my $missing             = 0;                 # number of required components missing

    my $minimal_threshold = 2;
    foreach my $c (@required_components) {
        $missing++ if (!defined($rh_components->{$c}));
        return 0   if ($missing == $minimal_threshold);
    }
    return 1;
}

my %valid_replacement_components = ('state' => 1,);

# determines which country code to use
# may also override other configuration if we are dealing with
# a dependent territory
sub _determine_country_code {
    my $self          = shift;
    my $rh_components = shift || return;

    # FIXME - validate it is a valid country
    return if (!defined($rh_components->{country_code}));

    if (my $cc = lc($rh_components->{country_code})) {

        # is it two letters long?
        return      if ($cc !~ m/^[a-z][a-z]$/);
        return 'GB' if ($cc eq 'uk');

        $cc = uc($cc);

        # check if the configuration tells us to use
        # the configuration of another country
        # used in cases of dependent territories like
        # American Samoa (AS) and Puerto Rico (PR)
        if (   defined($self->{templates}{$cc})
            && defined($self->{templates}{$cc}{use_country}))
        {
            my $old_cc = $cc;
            $cc = $self->{templates}{$cc}{use_country};
            if (defined($self->{templates}{$old_cc}{change_country})) {

                my $new_country = $self->{templates}{$old_cc}{change_country};
                if ($new_country =~ m/\$(\w*)/) {
                    my $component = $1;
                    if (defined($rh_components->{$component})) {
                        $new_country =~ s/\$$component/$rh_components->{$component}/;
                    } else {
                        $new_country =~ s/\$$component//;
                    }
                }
                $rh_components->{country} = $new_country;
            }
            if (defined($self->{templates}{$old_cc}{add_component})) {
                my $tmp = $self->{templates}{$old_cc}{add_component};
                my ($k, $v) = split(/=/, $tmp);
                # check whitelist of valid replacement components
                if (defined($valid_replacement_components{$k})) {
                    $rh_components->{$k} = $v;
                }
            }
        }

        if ($cc eq 'NL') {
            if (defined($rh_components->{state})) {
                if ($rh_components->{state} eq 'Curaçao') {
                    $cc = 'CW';
                    $rh_components->{country} = 'Curaçao';
                } elsif ($rh_components->{state} =~ m/^sint maarten/i) {
                    $cc = 'SX';
                    $rh_components->{country} = 'Sint Maarten';
                } elsif ($rh_components->{state} =~ m/^Aruba/i) {
                    $cc = 'AW';
                    $rh_components->{country} = 'Aruba';
                }
            }
        }
        return $cc;
    }
    return;
}

# hacks for bad country data
sub _fix_country {
    my $self          = shift;
    my $rh_components = shift || return;

    # is the country a number?
    # if so, and there is a state, use state as country
    if (defined($rh_components->{country})) {
        if (looks_like_number($rh_components->{country})) {
            if (defined($rh_components->{state})) {
                $rh_components->{country} = $rh_components->{state};
                delete $rh_components->{state};
            }
        }
    }
    return;
}

# sets and returns a state code
# note may also set other values in some odd edge cases
sub _add_state_code {
    my $self          = shift;
    my $rh_components = shift;
    return $self->_add_code('state', $rh_components);
}

sub _add_county_code {
    my $self          = shift;
    my $rh_components = shift;
    return $self->_add_code('county', $rh_components);
}

sub _add_code {
    my $self          = shift;
    my $keyname       = shift // return;
    my $rh_components = shift;
    return if !$rh_components->{country_code}; # do we know country?
    return if !$rh_components->{$keyname};     # do we know state/county?

    my $code = $keyname . '_code';

    if (defined($rh_components->{$code})) {    # do we already have code?
                                               # but could have situation
                                               # where code and long name are
                                               # the same which we want to correct
        if ($rh_components->{$code} ne $rh_components->{$keyname}) {
            return;
        }
    }

    # ensure country_code is uppercase as we use it as conf key
    $rh_components->{country_code} = uc($rh_components->{country_code});
    my $cc = $rh_components->{country_code};

    if (my $mapping = $self->{$code . 's'}{$cc}) {

        my $name    = $rh_components->{$keyname};
        my $uc_name = uc($name);

    LOCCODE: foreach my $abbrv (keys %$mapping) {

            my @confnames; # can have multiple names for the place
                           # for example in different languages

            if (is_hashref($mapping->{$abbrv})) {
                push(@confnames, values %{$mapping->{$abbrv}});
            } else {
                push(@confnames, $mapping->{$abbrv});
            }

            foreach my $confname (@confnames) {
                if ($uc_name eq uc($confname)) {
                    $rh_components->{$code} = $abbrv;
                    last LOCCODE;
                }
                # perhaps instead of passing in a name, we passed in a code
                # example: state => 'NC'
                # we want to turn that into
                #     state => 'North Carolina'
                #     state_code => 'NC'
                #
                if ($uc_name eq $abbrv) {
                    $rh_components->{$keyname} = $confname;
                    $rh_components->{$code}    = $abbrv;
                    last LOCCODE;
                }
            }
        }
        # didn't find a valid code or name

        # try again for odd variants like "United States Virgin Islands"
        if ($keyname eq 'state') {
            if (!defined($rh_components->{state_code})) {
                if ($cc eq 'US') {
                    if ($rh_components->{state} =~ m/^united states/i) {
                        my $state = $rh_components->{state};
                        $state =~ s/^United States/US/i;
                        foreach my $k (keys %$mapping) {
                            if (uc($state) eq uc($k)) {
                                $rh_components->{state_code} = $mapping->{$k};
                                last;
                            }
                        }
                    }
                    if ($rh_components->{state} =~ m/^washington,? d\.?c\.?/i) {
                        $rh_components->{state_code} = 'DC';
                        $rh_components->{state}      = 'District of Columbia';
                        $rh_components->{city}       = 'Washington';
                    }
                }
            }
        }
    }
    return $rh_components->{$code};
}

sub _apply_replacements {
    my $self          = shift;
    my $rh_components = shift;
    my $raa_rules     = shift;

    if ($debug){
        say STDERR "in _apply_replacements";
        say STDERR Dumper $raa_rules;
    }

    foreach my $component (keys %$rh_components) {
        foreach my $ra_fromto (@$raa_rules) {
            try {
                # do key specific replacement
                if ($ra_fromto->[0] =~ m/^$component=/) {
                    my $from = $ra_fromto->[0];
                    $from =~ s/^$component=//;
                    if ($rh_components->{$component} eq $from) {
                        $rh_components->{$component} = $ra_fromto->[1];
                    }
                } else {
                    my $regexp = qr/$ra_fromto->[0]/;
                    $rh_components->{$component} =~ s/$regexp/$ra_fromto->[1]/;
                }
            } catch {
                warn "invalid replacement: " . join(', ', @$ra_fromto);
            };
        }
    }
    return $rh_components;
}

sub _abbreviate {
    my $self    = shift;
    my $rh_comp = shift // return;

    # do we know the country?
    if (!defined($rh_comp->{country_code})) {
        if ($show_warnings){
            my $error_msg = 'no country_code, unable to abbreviate';
            if (defined($rh_comp->{country})) {
                $error_msg .= ' - country: ' . $rh_comp->{country};
            }
            warn $error_msg
        }
        return;
    }

    # do we have abbreviations for this country?
    my $cc = uc($rh_comp->{country_code});

    # 1. which languages?
    if (defined($self->{country2lang}{$cc})) {

        my @langs = split(/,/, $self->{country2lang}{$cc});

        foreach my $lang (@langs) {
            # do we have abbrv for this lang?
            if (defined($self->{abbreviations}->{$lang})) {

                my $rh_abbr = $self->{abbreviations}->{$lang};
                foreach my $comp_name (keys %$rh_abbr) {
                    next if (!defined($rh_comp->{$comp_name}));
                    foreach my $long (keys %{$rh_abbr->{$comp_name}}) {
                        my $short = $rh_abbr->{$comp_name}->{$long};
                        $rh_comp->{$comp_name} =~ s/\b$long\b/$short/;
                    }
                }
            } else {
                #warn "no abbreviations defined for lang $lang";
            }
        }
    }

    return $rh_comp;
}

# " abc,,def , ghi " => 'abc, def, ghi'
sub _clean {
    my $self = shift;
    my $out  = shift // return;
    if ($debug){
        say STDERR "entering _clean \n$out";
    }

    $out =~ s/\&#39\;/'/g;

    $out =~ s/[\},\s]+$//;
    $out =~ s/^[,\s]+//;

    $out =~ s/^- //; # line starting with dash due to a parameter missing

    $out =~ s/,\s*,/, /g;   # multiple commas to one
    $out =~ s/\h+,\h+/, /g; # one horiz whitespace behind comma
    $out =~ s/\h\h+/ /g;    # multiple horiz whitespace to one
    $out =~ s/\h\n/\n/g;    # horiz whitespace, newline to newline
    $out =~ s/\n,/\n/g;     # newline comma to just newline
    $out =~ s/,,+/,/g;      # multiple commas to one
    $out =~ s/,\n/\n/g;     # comma newline to just newline
    $out =~ s/\n\h+/\n/g;   # newline plus space to newline
    $out =~ s/\n\n+/\n/g;   # multiple newline to one

    # final dedupe across and within lines
    my @before_pieces = split(/\n/, $out);
    my %seen_lines;
    my @after_pieces;
    foreach my $line (@before_pieces) {
        $line =~ s/^\h+//g;
        $line =~ s/\h+$//g;
        $seen_lines{$line}++;
        next if ($seen_lines{$line} > 1);
        # now dedupe within the line
        my @before_words = split(/,/, $line);
        my %seen_words;
        my @after_words;
        foreach my $w (@before_words) {
            $w =~ s/^\h+//g;
            $w =~ s/\h+$//g;
            if (lc($w) ne 'new york') {
                $seen_words{$w}++;
            }
            next if ((defined($seen_words{$w})) && ($seen_words{$w} > 1));
            push(@after_words, $w);
        }
        $line = join(', ', @after_words);
        push(@after_pieces, $line);
    }
    $out = join("\n", @after_pieces);

    $out =~ s/^\s+//; # remove leading whitespace
    $out =~ s/\s+$//; # remove end whitespace

    $out .= "\n";     # add final newline
    return $out;      # we are done
}

sub _render_template {
    my $self       = shift;
    my $thtemplate = shift;
    my $components = shift;

    # Mustache calls it context
    my $context = clone($components);
    say STDERR 'context: ' . Dumper $context if ($debug);
    my $output = $thtemplate->render($context);

    $output = $self->_evaluate_template_lamdas($output);

    say STDERR "in _render before _clean: $output" if ($debug);
    $output = $self->_clean($output);

    # is it empty?
    # if yes and there is only one component then just use that one
    if ($output !~ m/\w/) {
        my @comps = sort keys %$components;
        if (scalar(@comps) == 1) {
            foreach my $k (@comps) {
                $output = $components->{$k};
            }
        } # FIXME what if more than one?
    }
    return $output;
}

# Text::Hogan apparently caches lambdas when rendering templates. In the past
# we needed our lambda 'first', example
#   {{#first}} {{{city}}} || {{{town}}} {{/first}}
# to evaluate the componentes. Whenever the lambda was called with different
# component values it consumed memory. Now replace with a simpler implementation
#
sub _replace_template_lambdas {
    my $self          = shift;
    my $template_text = shift;
    $template_text =~ s!\Q{{#first}}\E(.+?)\Q{{/first}}\E!FIRSTSTART${1}FIRSTEND!g;
    return $template_text;
}

# We only use a lambda named 'first'
sub _evaluate_template_lamdas {
    my $self = shift;
    my $text = shift;
    $text =~ s!FIRSTSTART\s*(.+?)\s*FIRSTEND!_select_first($1)!seg;
    return $text;
}

# '|| val1 ||  || val3' => 'val1'
sub _select_first {
    my $text = shift;
    my @a_parts = grep { length($_) } split(/\s*\|\|\s*/, $text);
    return scalar(@a_parts) ? $a_parts[0] : '';
}

my %small_district = (
    'br' => 1,
    'cr' => 1,
    'es' => 1,
    'ni' => 1,
    'py' => 1,
    'ro' => 1,
    'tg' => 1,
    'tm' => 1,
    'xk' => 1,
);

# correct the alias for "district"
# in OSM some countries use district to mean "city_district"
# others to mean "state_district"
sub _set_district_alias {
    my $self = shift;
    my $cc = shift;

    my $oldalias;
    if (defined($small_district{$cc})){
        $self->{component2type}{district} = 'neighbourhood';
        $oldalias = 'state_district';

        # add to the neighbourhood alias list
        # though of course we are just sticking it at the end
        push(@{$self->{component_aliases}{'neighbourhood'}}, 'district');

    } else {
        # set 'district' to be type 'state_district'
        $self->{component2type}{district} = 'state_district';
        $oldalias = 'neighbourhood';        

        # add to the state_district alias list
        push(@{$self->{component_aliases}{'state_district'}}, 'district');
    } 

    # remove from the old alias list
    my @temp = grep { $_ ne 'district' } @{$self->{component_aliases}{$oldalias}};
    $self->{component_aliases}{$oldalias} = \@temp;

    return;
}  


# returns []
sub _find_unknown_components {
    my $self       = shift;
    my $rh_components = shift;

    my %h_known   = map  { $_ => 1 } @{$self->{ordered_components}};
    my @a_unknown = grep { !exists($h_known{$_}) } sort keys %$rh_components;

    return \@a_unknown;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::Address::Formatter - take structured address data and format it according to the various global/country rules

=head1 VERSION

version 1.994

=head1 SYNOPSIS

  #
  # get the templates (or use your own)
  # git clone git@github.com:OpenCageData/address-formatting.git
  #
  my $GAF = Geo::Address::Formatter->new( conf_path => '/path/to/templates' );

  my $components = { ... }
  my $text = $GAF->format_address($components, { country => 'FR' } );
  my $rh_final_components = $GAF->final_components();
  #
  # or if we want shorter output
  # 
  my $short_text = $GAF->format_address($components, { country => 'FR', abbreviate => 1, });

=head2 new

  my $GAF = Geo::Address::Formatter->new( conf_path => '/path/to/templates' );

Returns one instance. The I<conf_path> is required.

Optional parameters are:

I<debug>: prints tons of debugging info for use in development.

I<no_warnings>: turns off a few warnings if configuration is not optimal.

I<only_address>: formatted will only contain known components (will not include POI names like). Note, can be overridden with optional param to format_address method.

=head2 final_components

  my $rh_components = $GAF->final_components();

returns a reference to a hash of the final components that are set at the
completion of B<format_address>. Warns if called before they have been set 
(unless I<no_warnings> was set at object creation).

=head2 format_address

  my $text = $GAF->format_address(\%components, \%options );

Given a structures address (hashref) and options (hashref) returns a
formatted address.

Possible options are:

    'abbreviate', if supplied common abbreviations are applied
    to the resulting output.

    'address_template', a mustache format template to be used instead of the template
    defined in the configuration

    'country', which should be an uppercase ISO 3166-1:alpha-2 code
    e.g. 'GB' for Great Britain, 'DE' for Germany, etc.
    If ommited we try to find the country in the address components.

    'only_address', same as only_address global option but set at formatting level

=head1 DESCRIPTION

You have a structured postal address (hash) and need to convert it into a
readable address based on the format of the address country.

For example, you have:

  {
    house_number => 12,
    street => 'Avenue Road',
    postcode => 45678,
    city => 'Deville'
  }

you need:

  Great Britain: 12 Avenue Road, Deville 45678
  France: 12 Avenue Road, 45678 Deville
  Germany: Avenue Road 12, 45678 Deville
  Latvia: Avenue Road 12, Deville, 45678

It gets more complicated with 200+ countries and territories and dozens more
address components to consider.

This module comes with a minimal configuration to run tests. Instead of
developing your own configuration please use (and contribute to)
those in https://github.com/OpenCageData/address-formatting
which includes test cases.

Together we can address the world!

=head1 AUTHOR

Ed Freyfogle

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Opencage GmbH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
