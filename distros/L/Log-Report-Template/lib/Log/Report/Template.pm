# Copyrights 2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Log::Report::Template;
use vars '$VERSION';
$VERSION = '0.12';

use base 'Template';

use Log::Report 'log-report-template';
use Log::Report::Template::Textdomain ();
# use Log::Report::Extract::Template on demand

use File::Find        qw(find);
use Scalar::Util      qw(blessed);
use Template::Filters ();
use String::Print     ();


sub new
{   my $class = shift;
    my $self = $class->SUPER::new(@_) or panic $class->error;
    $self;
}

sub _init($)
{   my ($self, $args) = @_;

    # Add a filter object we can dynamically add new filters to
    my $filters = $self->{LRT_filters} = {};

    push @{$args->{LOAD_FILTERS}}
      , Template::Filters->new({ FILTERS => $filters });

    $self->SUPER::_init($args);

    my $delim = $self->{LRT_delim} = $args->{DELIMITER} || ':';
    my $incl = $args->{INCLUDE_PATH} || [];
    $self->{LRT_path} = ref $incl eq 'ARRAY' ? $incl : [ split $delim, $incl ];

    my $handle_errors = $args->{processing_errors} || 'NATIVE';
    if($handle_errors eq 'EXCEPTION') { $self->{LRT_exceptions} = 1 }
    elsif($handle_errors ne 'NATIVE')
    {   error __x"illegal value '{value}' for 'processing_errors' option"
          , value => $handle_errors;
    }

    $self->{LRT_formatter} = $self->_createFormatter($args);
    $self->_defaultFilters;
    $self;
}

sub _createFormatter($)
{   my ($self, $args) = @_;
    my $formatter = $args->{formatter};
    return $formatter if ref $formatter eq 'CODE';

    my $syntax = $args->{template_syntax} || 'HTML';
    my $modifiers = $self->_collectModifiers($args);

    my $sp     = String::Print->new
      ( encode_for => ($syntax eq 'HTML' ? $syntax : undef) 
      , modifiers  => $modifiers
      );

    sub { $sp->sprinti(@_) };
}

#---------------

sub formatter() { shift->{LRT_formatter} }

#---------------

sub addTextdomain($%) {
    my ($self, %args) = @_;

    if(my $only = $args{only_in_directory})
    {   my $delim = $self->{LRT_delim};
        $only     = $args{only_in_directory} = [ split $delim, $only ]
    		if ref $only ne 'ARRAY';

        my @incl  = $self->_incl_path;
        foreach my $dir (@$only)
        {   next if grep $_ eq $dir, @incl;
            error __x"directory {dir} not in INCLUDE_PATH, used by {option}"
              , dir => $dir, option => 'addTextdomain(only_in_directory)';
        }
    }

    my $name    = $args{name};
    ! textdomain $name, 'EXISTS'
        or error __x"textdomain '{name}' already exists", name => $name;

    my $lexicon = delete $args{lexicon} || delete $args{lexicons}
    	or error __x"textdomain '{name}' does not specify the lexicon directory"
            , name => $name;

    if(ref $lexicon eq 'ARRAY')
    {   @$lexicon < 2
        or error __x"textdomain '{name}' has more than one lexicon directory"
            , name => $name;

        $lexicon = $lexicon->[0]
    	or error __x"textdomain '{name}' does not specify the lexicon directory"
            , name => $name;
    }

    -d $lexicon
        or error __x"lexicon directory {dir} for textdomain '{name}' does not exist"
           , dir => $lexicon, name => $name;
    $args{lexicon} = $lexicon;

    my $domain  = Log::Report::Template::Textdomain->new(%args);
    textdomain $domain;

    my $func    = $domain->function;
    if((my $other) = grep $func eq $_->function, $self->_domains)
    {   error __x"translation function '{func}' already in use by textdomain '{name}'"
          , func => $func, name => $other->name;
    }
    $self->{LRT_domains}{$name}     = $domain;

    # call as function or as filter
    $self->_stash->{$func}   = $domain->translationFunction($self->service);
    $self->_filters->{$func} = [ $domain->translationFilter, 1 ];
    $domain;
}

sub _incl_path() { @{shift->{LRT_path}} }
sub _filters()   { shift->{LRT_filters} }
sub _stash()     { shift->service->context->stash }
sub _domains()   { values %{$_[0]->{LRT_domains} } }



sub extract(%)
{   my ($self, %args) = @_;

    eval "require Log::Report::Extract::Template";
    panic $@ if $@;

    my $stats   = $args{show_stats} || 0;
    my $charset = $args{charset}    || 'UTF-8';
    my $write   = exists $args{write_tables} ? $args{write_tables} : 1;

    my @filenames;
    if(my $fns  = $args{filenames} || $args{filename})
    {   push @filenames, ref $fns eq 'ARRAY' ? @$fns : $fns;
    }
    else
    {   my $match = $args{filename_match} || qr/\.tt2?$/;
        my $filter = sub {
            my $name = $File::Find::name;
           push @filenames, $name if -f $name && $name =~ $match;
        };
    	foreach my $dir ($self->_incl_path)
        {   trace "scan $dir for template files";
            find { wanted => sub { $filter->($File::Find::name) }
                 , no_chdir => 1}, $dir;
    	}
    }

    foreach my $domain ($self->_domains)
    {   my $function = $domain->function;
    	my $name     = $domain->name;

    	trace "extracting msgids for '$function' from domain '$name'";

        my $extr = Log::Report::Extract::Template->new
          ( lexicon => $domain->lexicon
          , domain  => $name
          , pattern => "TT2-$function"
          , charset => $charset
          );

    	$extr->process($_) for @filenames;

    	$extr->showStats if $stats;
    	$extr->write     if $write;
    }
}

#------------

sub _cols_factory(@)
{   my $self = shift;
    my $params = ref $_[-1] eq 'HASH' ? pop : undef;
    my @blocks = @_ ? @_ : 'td';
    if(@blocks==1 && $blocks[0] =~ /\$[1-9]/)
    {   my $pattern = shift @blocks;
        return sub {   # second syntax
    	    my @cols = split /\t/, $_[0];
    	    $pattern =~ s/\$([0-9]+)/$cols[$1-1] || ''/ge;
			$pattern;
        }
    }

    sub {   # first syntax
    	my @cols = split /\t/, $_[0];
    	my @wrap = @blocks;
    	my @out;
    	while(@cols)
        {   push @out, "<$wrap[0]>$cols[0]</$wrap[0]>";
            shift @cols;
            shift @wrap if @wrap > 1;
        }
        join '', @out;
    }
}


sub _br_factory(@)
{   my $self = shift;
    my $params = ref $_[-1] eq 'HASH' ? pop : undef;
    return sub {
        my $templ = shift or return '';
        for($templ)
        {   s/\A[\s\n]*\n//;     # leading blank lines
            s/\n[\s\n]*\n/\n/g;  # double blank links
            s/\n[\s\n]*\z/\n/;   # trailing blank lines
            s/\s*\n/<br>\n/gm;   # trailing blanks per line
        }
        $templ;
    }
}

sub _defaultFilters()
{   my $self   = shift;
    my $filter = $self->_filters;
    $filter->{cols} = [ \&_cols_factory, 1 ];
    $filter->{br}   = [ \&_br_factory,   1 ];
    $filter;
}

#------------


sub _collectModifiers($)
{   my ($self, $args) = @_;

    # First match will be used
    my @modifiers = @{$args->{modifiers} || []};

    # More default extensions expected here.  String::Print already
    # adds a bunch.

    \@modifiers;
}

#------------


{ # Log::Report exports 'error', and we use that.  Our base-class
  # 'Template' however, also has a method named error() as well.
  # Gladly, they can easily be separated.

  # no warnings 'redefined' misbehaves, at least for perl 5.16.2
  no warnings;  

  sub error()
  {
    return Log::Report::error(@_)
        unless blessed $_[0] && $_[0]->isa('Template');

    return shift->SUPER::error(@_)
        unless $_[0]->{LRT_exceptions};

    @_ or panic "inexpected call to collect errors()";

    # convert Template errors into Log::Report errors
    Log::Report::error($_[1]);
  }
}


#------------

1;
