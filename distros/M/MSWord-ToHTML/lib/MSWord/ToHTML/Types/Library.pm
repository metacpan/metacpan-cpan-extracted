package MSWord::ToHTML::Types::Library;
{
  $MSWord::ToHTML::Types::Library::VERSION = '0.010';
}

use namespace::autoclean;
use strictures 1;
use MooseX::Types::Moose qw/Str/;
use MooseX::Types::IO::All qw/:all/;
use Moose::Util::TypeConstraints;
use MooseX::Types -declare => [qw/MyFile MSDoc MSDocX/];
use Try::Tiny;
use Text::Extract::Word;
use Archive::Zip qw/:ERROR_CODES :CONSTANTS/;
use Archive::Zip::MemberRead;
use File::Spec;

subtype MyFile, as IO_All, where {
  length($_) > 0;
}, message {
  "Did you pass a file?";
};

coerce MyFile, from Str, via { to_IO_All($_) };

subtype MSDoc, as MyFile, where {
  try {
    local *STDERR;
    open( STDERR, '>', File::Spec->devnull() );
    Text::Extract::Word->new( $_->filepath . $_->filename );
  };
}, message {
  "$_ does not appear to be a Word doc file";
};

coerce MSDoc, from MyFile | IO_All, via {$_};

subtype MSDocX, as MyFile, where {
  my $unzip = Archive::Zip->new;
  Archive::Zip->new( $_->filepath . $_->filename )
    && Archive::Zip::MemberRead->new( $unzip, "word/document.xml" );
}, message {
  "$_ does not appear to be a Word docx file";
};

coerce MSDocX, from MyFile | IO_All, via {$_};

__PACKAGE__->meta->make_immutable;

1;
