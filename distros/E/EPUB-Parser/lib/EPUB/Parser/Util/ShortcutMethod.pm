package EPUB::Parser::Util::ShortcutMethod;
use strict;
use warnings;
use Exporter qw/import/;

our @EXPORT_OK = qw/
 title creator language identifier
 items_by_media items_by_media_type
 toc_list
 /;

## metadata
sub title      { shift->opf->metadata->title      }
sub creator    { shift->opf->metadata->creator    }
sub language   { shift->opf->metadata->language   }
sub identifier { shift->opf->metadata->identifier }


## manifest
sub items_by_media {
    shift->opf->manifest->items_by_media;
}

sub items_by_media_type {
    shift->opf->manifest->items_by_media_type(@_);
}


## navi
sub toc_list { shift->navi->toc->list }


1;

__END__

