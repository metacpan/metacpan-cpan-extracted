#!/usr/bin/env perl

## no critic
# This chunk of stuff was generated by App::FatPacker. To find the original
# file's code, look for the end of this BEGIN block or the string 'FATPACK'
BEGIN {
my %fatpacked;

$fatpacked{"Gentoo/PerlMod/Version.pm"} = '#line '.(1+__LINE__).' "'.__FILE__."\"\n".<<'GENTOO_PERLMOD_VERSION';
  use 5.006;use strict;use warnings;package Gentoo::PerlMod::Version;our$VERSION='v0.8.1';our$AUTHORITY='cpan:KENTNL';use Sub::Exporter::Progressive -setup=>{exports=>[qw(gentooize_version)]};use version 0.77;sub gentooize_version {my ($perlver,$config)=@_;$config ||= {};if (not defined$perlver){return _err_perlver_undefined($config)}$config->{lax}=0 unless defined$config->{lax};if (_env_hasopt('always_lax')){$config->{lax}=_env_getopt('always_lax')}if ($perlver =~ /\Av?[\d.]+\z/msx){return _lax_cleaning_0($perlver)}if ($perlver =~ /\Av?[\d._]+(-TRIAL)?\z/msx){if ($config->{lax}> 0){return _lax_cleaning_1($perlver)}return _err_matches_trial_regex_nonlax($perlver,$config)}if (2==$config->{lax}){return _lax_cleaning_2($perlver)}return _err_not_decimal_or_trial($perlver,$config)}my$char_map={(map {$_=>$_}0 .. 9),(map {chr($_ + 65)=>$_ + 10}0 .. 25),(map {chr($_ + 97)=>$_ + 10}0 .. 25),};sub _code_for {my$char=shift;if (not exists$char_map->{$char}){my$char_ord=ord$char;return _err_bad_char($char,$char_ord)}return$char_map->{$char}}sub _enc_pair {my (@tokens)=@_;if (not @tokens){return q{}}if (@tokens < 2){return _code_for(shift@tokens)}return (_code_for($tokens[0])* 36)+ (_code_for($tokens[1]))}sub _ascii_to_int {my$string=shift;my@chars=split //msx,$string;my@output;while (@chars){push@output,_enc_pair(splice@chars,0,2,())}return join q{.},@output}sub _lax_cleaning_0 {my$version=shift;return _expand_numeric($version)}sub _lax_cleaning_1 {my$version=shift;my$isdev=0;my$prereleasever=undef;if ($version =~ s/-TRIAL\z//msx){$isdev=1}if ($version =~ s/_(.*)\z/$1/msx){$prereleasever="$1";$isdev=1;if ($prereleasever =~ /_/msx){return _err_lax_multi_underscore($version)}}$version=_expand_numeric($version);if ($isdev){$version .= '_rc'}return$version}sub _lax_cleaning_2 {my$version=shift;my$istrial=0;my$has_v=0;if ($version =~ s/-TRIAL\z//msx){$istrial=1}if ($version =~ s/\Av//msx){$has_v=1}my@parts=split /([._])/msx,$version;my@out;for (@parts){if (/\A[_.]\z/msx){push@out,$_;next}if (/\A\d\z/msx){push@out,$_;next}push@out,_ascii_to_int($_)}my$version_out=join q{},@out;if ($istrial){$version_out .= '-TRIAL'}if ($has_v){$version_out='v' .$version_out}return _lax_cleaning_1($version_out)}sub _expand_numeric {my$perlver=shift;my$ver=version->parse($perlver)->normal;$ver =~ s/\Av//msx;my@tokens=split /[.]/msx,$ver;my@out;for (@tokens){s/\A0+([1-9])/$1/msx;push@out,$_}return join q{.},@out}BEGIN {for my$err (qw(perlver_undefined matches_trial_regex_nonlax not_decimal_or_trial bad_char lax_multi_underscore)){my$code=sub {require Gentoo::PerlMod::Version::Error;my$sub=Gentoo::PerlMod::Version::Error->can($err);goto$sub};no strict 'refs';*{__PACKAGE__ .'::_err_' .$err}=$code}for my$env (qw(opts hasopt getopt)){my$code=sub {require Gentoo::PerlMod::Version::Env;my$sub=Gentoo::PerlMod::Version::Env->can($env);goto$sub};no strict 'refs';*{__PACKAGE__ .'::_env_' .$env}=$code}}1;
GENTOO_PERLMOD_VERSION

$fatpacked{"Gentoo/PerlMod/Version/Env.pm"} = '#line '.(1+__LINE__).' "'.__FILE__."\"\n".<<'GENTOO_PERLMOD_VERSION_ENV';
  use 5.006;use strict;use warnings;package Gentoo::PerlMod::Version::Env;our$VERSION='v0.8.1';our$AUTHORITY='cpan:KENTNL';my$state;my$env_key='GENTOO_PERLMOD_VERSION_OPTS';sub opts {return$state if defined$state;$state={};return$state if not defined$ENV{$env_key};my (@tokes)=split /\s+/msx,$ENV{$env_key};for my$token (@tokes){if ($token =~ /\A([^=]+)=(.+)\z/msx){$state->{"$1"}="$2"}elsif ($token =~ /\A-(.+)\z/msx){delete$state->{"$1"}}else {$state->{$token}=1}}return$state}sub hasopt {my ($opt)=@_;return exists opts()->{$opt}}sub getopt {my ($opt)=@_;return opts()->{$opt}}1;
GENTOO_PERLMOD_VERSION_ENV

$fatpacked{"Gentoo/PerlMod/Version/Error.pm"} = '#line '.(1+__LINE__).' "'.__FILE__."\"\n".<<'GENTOO_PERLMOD_VERSION_ERROR';
  use 5.006;use strict;use warnings;package Gentoo::PerlMod::Version::Error;our$VERSION='v0.8.1';our$AUTHORITY='cpan:KENTNL';BEGIN {for my$env (qw(opts hasopt getopt)){my$code=sub {require Gentoo::PerlMod::Version::Env;my$sub=Gentoo::PerlMod::Version::Env->can($env);goto$sub};no strict 'refs';*{__PACKAGE__ .'::_env_' .$env}=$code}}sub perlver_undefined {my ($config)=@_;return _fatal({code=>'perlver_undefined',config=>$config,message=>'Argument \'$perlver\' to gentooize_version was undefined',},)}sub matches_trial_regex_nonlax {my ($perlver,$config,)=@_;return _fatal({code=>'matches_trial_regex_nonlax',config=>$config,want_lax=>1,message=>'Invalid version format (non-numeric data, either _ or -TRIAL ).',message_extra_tainted=>qq{ Version: >$perlver< },version=>$perlver,},)}sub not_decimal_or_trial {my ($perlver,$config)=@_;return _fatal({code=>'not_decimal_or_trial',config=>$config,want_lax=>2,message=>'Invalid version format (non-numeric/ASCII data).',message_extra_tainted=>qq{ Version: >$perlver< },version=>$perlver,},)}sub bad_char {my ($char,$char_ord)=@_;return _fatal({code=>'bad_char',message=>'A Character in the version is not in the ascii-to-int translation table.',message_extra_tainted=>qq{ Missing character: $char ( $char_ord )},},)}sub lax_multi_underscore {my ($version)=@_;return _fatal({code=>'lax_multi_underscore',message=>q{More than one _ in a version is not permitted},message_extra_tainted=>qq{ Version: >$version< },version=>$version,},)}sub _format_error {my ($conf)=@_;my$message=$conf->{message};if (exists$conf->{want_lax}){my$lax=$conf->{want_lax};$message .= qq{\n Set { lax => $lax } for more permissive behaviour. }}if (_env_hasopt('taint_safe')){return$message}if (_env_hasopt('carp_debug')){$conf->{env_config}=_env_opts;require Data::Dumper;local$Data::Dumper::Indent=2;local$Data::Dumper::Purity=0;local$Data::Dumper::Useqq=1;local$Data::Dumper::Terse=1;local$Data::Dumper::Quotekeys=0;return Data::Dumper::Dumper($conf)}if (exists$conf->{'message_extra_tainted'}){$message .= $conf->{'message_extra_tainted'}}if (exists$conf->{'stack'}){for (@{$conf->{stack}}){if ($_->[0]!~ /\AGentoo::PerlMod::Version(?:|::Error|::Env)\z/msx){$message .= sprintf qq[\n - From %s in %s at line %s\n],$_->[0]|| q[],$_->[1]|| q[],$_->[2]|| q[];last}}}return$message}use overload q[""]=>\&_format_error;sub _fatal {my ($conf)=@_;require Carp;$conf->{stack}=[map {[$_->[0],$_->[1],$_->[2],]}map {[caller $_,]}0 .. 10,];return Carp::croak(bless$conf,__PACKAGE__)}1;
GENTOO_PERLMOD_VERSION_ERROR

$fatpacked{"Sub/Exporter/Progressive.pm"} = '#line '.(1+__LINE__).' "'.__FILE__."\"\n".<<'SUB_EXPORTER_PROGRESSIVE';
  package Sub::Exporter::Progressive;$Sub::Exporter::Progressive::VERSION='0.001013';use strict;use warnings;sub _croak {require Carp;&Carp::croak}sub import {my ($self,@args)=@_;my$inner_target=caller;my$export_data=sub_export_options($inner_target,@args);my$full_exporter;no strict 'refs';no warnings 'once';@{"${inner_target}::EXPORT_OK"}=@{$export_data->{exports}};@{"${inner_target}::EXPORT"}=@{$export_data->{defaults}};%{"${inner_target}::EXPORT_TAGS"}=%{$export_data->{tags}};*{"${inner_target}::import"}=sub {use strict;my ($self,@args)=@_;if (grep {length ref $_ or $_ !~ / \A [:-]? \w+ \z /xm}@args){_croak 'your usage of Sub::Exporter::Progressive requires Sub::Exporter to be installed' unless eval {require Sub::Exporter};$full_exporter ||= Sub::Exporter::build_exporter($export_data->{original});goto$full_exporter}elsif (defined((my ($num)=grep {m/^\d/}@args)[0])){_croak "cannot export symbols with a leading digit: '$num'"}else {require Exporter;s/ \A - /:/xm for@args;@_=($self,@args);goto \&Exporter::import}};return}my$too_complicated=<<'DEATH';sub sub_export_options {my ($inner_target,$setup,$options)=@_;my@exports;my@defaults;my%tags;if (($setup||'')eq '-setup'){my%options=%$options;OPTIONS: for my$opt (keys%options){if ($opt eq 'exports'){_croak$too_complicated if ref$options{exports}ne 'ARRAY';@exports=@{$options{exports}};_croak$too_complicated if grep {length ref $_}@exports}elsif ($opt eq 'groups'){%tags=%{$options{groups}};for my$tagset (values%tags){_croak$too_complicated if grep {length ref $_ or $_ =~ / \A - (?! all \b ) /x}@{$tagset}}@defaults=@{$tags{default}|| []}}else {_croak$too_complicated}}@{$_}=map {/ \A  [:-] all \z /x ? @exports : $_}@{$_}for \@defaults,values%tags;$tags{all}||= [@exports ];my%exports=map {$_=>1}@exports;my@errors=grep {not $exports{$_}}@defaults;_croak join(', ',@errors)." is not exported by the $inner_target module\n" if@errors}return {exports=>\@exports,defaults=>\@defaults,original=>$options,tags=>\%tags,}}1;
  You are using Sub::Exporter::Progressive, but the features your program uses from
  Sub::Exporter cannot be implemented without Sub::Exporter, so you might as well
  just use vanilla Sub::Exporter
  DEATH
SUB_EXPORTER_PROGRESSIVE

s/^  //mg for values %fatpacked;

my $class = 'FatPacked::'.(0+\%fatpacked);
no strict 'refs';
*{"${class}::files"} = sub { keys %{$_[0]} };

if ($] < 5.008) {
  *{"${class}::INC"} = sub {
    if (my $fat = $_[0]{$_[1]}) {
      my $pos = 0;
      my $last = length $fat;
      return (sub {
        return 0 if $pos == $last;
        my $next = (1 + index $fat, "\n", $pos) || $last;
        $_ .= substr $fat, $pos, $next - $pos;
        $pos = $next;
        return 1;
      });
    }
  };
}

else {
  *{"${class}::INC"} = sub {
    if (my $fat = $_[0]{$_[1]}) {
      open my $fh, '<', \$fat
        or die "FatPacker error loading $_[1] (could be a perl installation issue?)";
      return $fh;
    }
    return;
  };
}

unshift @INC, bless \%fatpacked, $class;
  } # END OF FATPACK CODE

## use critic
use 5.006;
use strict;
use warnings;

package Gentoo::PerlMod::Version::Tool;

our $VERSION = '0.8.1';

# PODNAME: gentoo-perlmod-version.pl

# ABSTRACT: Command line utility for translating CPAN versions to Gentoo equivalents.

# AUTHORITY

## no critic (ProhibitPunctuationVar)
use Gentoo::PerlMod::Version qw( gentooize_version );
use Carp qw( croak );

for (@ARGV) {
  if (/\A--?h/msx) {
    die <<"EOF";

    gentoo-perlmod-version.pl 1.4 1.5 1.6
    gentoo-perlmod-version.pl --lax=1 1.4_5 1.5_6
    gentoo-perlmod-version.pl --lax=2 1.4.DONTDOTHISPLEASE432

    echo 1.4 | gentoo-perlmod-version.pl
    echo 1.4-5 | gentoo-perlmod-version.pl --lax=1
    echo 1.4.NOOOOO | gentoo-perlmod-version.pl --lax=2

    SOMEVAR="\$(  gentoo-perlmod-version.pl --oneshot 1.4 )"
    SOMEVAR="\$(  gentoo-perlmod-version.pl --oneshot 1.4 1.5 )" # Invalid, dies
    SOMEVAR="\$(  gentoo-perlmod-version.pl --oneshot 1.4_5 )" # Invalid, dies
    SOMEVAR="\$(  gentoo-perlmod-version.pl --lax=1 --oneshot 1.4_5 )" # Ok


See perldoc for Gentoo::PerlMod::Version for more information.

    perldoc Gentoo::PerlMod::Version

EOF

  }
}

my $lax     = 0;
my $oneshot = 0;

for ( 0 .. $#ARGV ) {
  next unless $ARGV[$_] =~ /\A--lax=(\d+)\z/msx;
  $lax = 0 + $1;
  splice @ARGV, $_, 1, ();
  last;
}
for ( 0 .. $#ARGV ) {
  next unless '--oneshot' eq $ARGV[$_];
  $oneshot = 1;
  splice @ARGV, $_, 1, ();
  last;
}

if ($oneshot) {
  croak 'Too many versions given to --oneshot mode' if $#ARGV > 0;
  my $v = gentooize_version( $ARGV[0], { lax => $lax } );
  print $v or croak "Print Error $!";
  exit 0;
}

if (@ARGV) {
  for (@ARGV) {
    map_version( $_, $lax );
  }
}
else {
  while (<>) {
    chomp;
    map_version( $_, $lax );
  }
}

sub map_version {
  my ( $version, $laxness ) = @_;
  print "$version => " . gentooize_version( $version, { lax => $laxness } ) or croak "Print error $!";
  print "\n" or croak "Print error $!";
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

gentoo-perlmod-version.pl - Command line utility for translating CPAN versions to Gentoo equivalents.

=head1 VERSION

version v0.8.1

=head1 SYNOPSIS

    gentoo-perlmod-version.pl 1.4 1.5 1.6
    gentoo-perlmod-version.pl --lax=1 1.4_5 1.5_6
    gentoo-perlmod-version.pl --lax=2 1.4.DONTDOTHISPLEASE432

    echo 1.4 | gentoo-perlmod-version.pl
    echo 1.4-5 | gentoo-perlmod-version.pl --lax=1
    echo 1.4.NOOOOO | gentoo-perlmod-version.pl --lax=2

    SOMEVAR="$(  gentoo-perlmod-version.pl --oneshot 1.4 )"
    SOMEVAR="$(  gentoo-perlmod-version.pl --oneshot 1.4 1.5 )" # Invalid, dies
    SOMEVAR="$(  gentoo-perlmod-version.pl --oneshot 1.4_5 )" # Invalid, dies
    SOMEVAR="$(  gentoo-perlmod-version.pl --lax=1 --oneshot 1.4_5 )" # Ok

See C<perldoc> for L<< C<Gentoo::PerlMod::Versions> documentation|Gentoo::PerlMod::Version >> for more information.

    perldoc Gentoo::PerlMod::Version

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
