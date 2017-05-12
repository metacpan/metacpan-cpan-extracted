#

package HTML::WebMake::DataSources::SVFile;

require Exporter;
use HTML::WebMake::DataSourceBase;
use Carp;
use strict;

use vars	qw{
  	@ISA @EXPORT
};

@ISA = qw(HTML::WebMake::DataSourceBase);
@EXPORT = qw();

###########################################################################

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my $self = $class->SUPER::new (@_);
  bless ($self, $class);
  $self;
}

# -------------------------------------------------------------------------

sub add {
  my ($self) = @_;
  local ($_);

  my @s;
  my @lines;

  # if we're doing a <contenttable>, stat the .wmk file, and use the
  # passed-in text instead of loading it from an external file.
  #
  if (defined $self->{parent}->{ctable_wmkfile})
  {
    $self->{src} = $self->{parent}->{ctable_wmkfile}->{filename};
    @s = stat $self->{src};
    @lines = split (/\n/, $self->{parent}->{ctable_text});

  } else {
    if (!open (IN, $self->{src})) {
      warn "can't open ".$self->as_string()." src file \"$self->{src}\": $!\n";
      return;
    }
    @s = stat IN;
    @lines = (<IN>);
    close IN;

    $self->{main}->add_source_files ($self->{src});
  }

  my $patt = $self->{main}->{util}->glob_to_re ($self->{name});

  my $nfield = $self->{attrs}->{namefield};
  my $vfield = $self->{attrs}->{valuefield};
  my $delim = $self->{attrs}->{delimiter};
  $nfield ||= 1;
  $vfield ||= 2;
  $nfield--;            # adjust count-from-1 to -from-0
  $vfield--;
  $delim ||= "\t";

  foreach $_ (@lines) {
    next unless /\S/;
    my @fields = split (/\Q${delim}\E/, $_);
    if (defined $fields[$nfield] && $fields[$nfield] =~ /^${patt}$/)
    {
      my $name = $fields[$nfield];
      $_ = $fields[$vfield]; $_ ||= '';

      # use this file's filename and stat details, so dependency checking
      # will work if the file changes
      my $wmkf = new HTML::WebMake::File($self->{main}, $self->{src}, $s[9]);

      my $fixed = $self->{parent}->fixname ($name);
      $self->{parent}->add_file_to_list ($fixed);
      $self->{parent}->add_text ($fixed, $_, $self->{src}, $s[9]);
    }
  }
}

# -------------------------------------------------------------------------

sub get_location_contents {
  my ($self, $fname) = @_;
  croak __FILE__." get_location_contents called";
}

# -------------------------------------------------------------------------

# pretty simple for separated-value files: the modtime of values read
# from such a file is the modtime of the SV file itself.
#
sub get_location_mod_time {
  my ($self, $fname) = @_;
  $fname =~ /^svfile:/;
  $self->{main}->cached_get_modtime ($');
}

1;
