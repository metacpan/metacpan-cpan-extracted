package Document::TriPart::Cabinet::App;

use strict;
use warnings;

use Document::TriPart::Cabinet;
use Document::TriPart::Cabinet::Storage::Disk;

use Getopt::Chain;
use Data::UUID::LibUUID;
use Carp;
use Path::Abstract;
use DateTime;
use Getopt::Chain;
use Term::Prompt;
use Text::ASCIITable;

local $Term::Prompt::MULTILINE_INDENT = undef;

my $storage = Document::TriPart::Cabinet::Storage::Disk->new( dir => Path::Class::Dir->new( 'cabinet' ) );
my $cabinet = Document::TriPart::Cabinet->new( storage => $storage );

sub abort(@) {
    print join "", @_, "\n" if @_;
    exit -1;
}

sub find {
    my @criteria = @_;

    return unless @criteria;

    my $uuid = $criteria[0];

    return ( $cabinet->load( $uuid ), undef, 1 );
}

######
# Do #
######

sub do_list {
    my $search = shift;

#    $search = scalar $journal->posts unless $search;
#    my @posts = $search->search( undef, { order_by => [qw/ created /] } )->all;

    my $tb = Text::ASCIITable->new({ hide_HeadLine => 1 });
    $tb->setCols( '', '', '' );
    $tb->addRow( 'Search is broken!' );
#    $tb->addRow( $_->uuid, $_->title, $_->folder ) for @posts;
    print $tb;
}

sub do_new {
    my ($folder, $title) = @_;

    my $document = $cabinet->create;

    $document->edit;

    return $document;
}

sub do_find {
    my @criteria = @_;

    unless (@criteria) {
        do_list;
        return;
    }

    my ($post, $search, $count) = find @criteria;

    abort "No post found matching your criteria" unless $count;

    choose $search if $count > 1;

    return $post;
}

sub do_choose {
    my $search = shift;

    print "Too many posts found matching your criteria\n";

    list $search;
}

#######
# Run #
#######

sub run {

    Getopt::Chain->process(

        commands => {

            DEFAULT => sub {
                my $context = shift;
                local @_ = $context->remaining_arguments;

                if (defined (my $command = $context->command)) {
                    print <<_END_;
    Unknown command: $command
_END_
                }

                print <<_END_;
    Usage: $0 <command>

        new
        edit <criteria> ...
        list 
        assets <key>

_END_
                do_list unless @_;
            },

            new => {
                options => [qw/link=s/],

                run => sub {
                    my $context = shift;

                    my $post = do_new;
                },
            },

            edit => sub {
                my $context = shift;
                local @_ = $context->remaining_arguments; # TODO Should pass in remaining arguments

                return do_list unless @_;

                my ($document, $search, $count) = find @_;

                if ($document) {
                    $document->edit;
                }
                else {
                    return do_choose $search if $count > 1;
                    if (prompt y => "Post not found. Do you want to start it?", undef, 'N') {
                        my $document = do_new;
                    }
                }
            },

            assets => sub {
                my $context = shift;
                local @_ = $context->remaining_arguments;

                return unless my $post = do_find @_;

                my $assets_dir = $post->assets_dir;

                if (-d $assets_dir) {
                    print "$assets_dir already exists\n";
                }
                else {
                    $assets_dir->mkpath;
                }
            },

            list => sub {
                my $context = shift;
                local @_ = $context->remaining_arguments;

                my $search;
                (undef, $search) = find @_ if $_;

                do_list $search;
            },
        },
    );

}

1;

__END__
1;
