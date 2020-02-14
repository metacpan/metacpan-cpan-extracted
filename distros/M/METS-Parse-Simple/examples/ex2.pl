#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use METS::Parse::Simple;

# Example METS data.
my $mets_data = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<mets xmlns:xlink="http://www.w3.org/TR/xlink">
  <fileSec>
    <fileGrp ID="IMGGRP" USE="Images">
      <file ID="IMG00001" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00001" MIMETYPE="image/tiff" SEQ="1" SIZE="5184000" GROUPID="1">
        <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855r.tif" />
      </file>
      <file ID="IMG00002" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00002" MIMETYPE="image/tiff" SEQ="2" SIZE="5200228" GROUPID="2">
        <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855v.tif" />
      </file>
    </fileGrp>
    <fileGrp ID="PDFGRP" USE="PDF">
      <file ID="PDF00001" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00001" MIMETYPE="text/pdf" SEQ="1" SIZE="251967" GROUPID="1">
        <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855r.pdf" />
      </file>
      <file ID="PDF00002" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00002" MIMETYPE="text/pdf" SEQ="2" SIZE="172847" GROUPID="2">
        <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855v.pdf" />
      </file>
    </fileGrp>
  </fileSec>
</mets>
END

# Object.
my $obj = METS::Parse::Simple->new;

# Parse.
my $mets_hr = $obj->parse($mets_data);

# Dump to output.
p $mets_hr;

# Output like:
\ {
    fileSec       {
        fileGrp   [
            [0] {
                file   [
                    [0] {
                        ADMID      "IMGPARAM00001",
                        CREATED    "2006-06-20T12:00:00",
                        FLocat     {
                            LOCTYPE      "URL",
                            xlink:href   "file://./003855/003855r.tif"
                        },
                        GROUPID    1,
                        ID         "IMG00001",
                        MIMETYPE   "image/tiff",
                        SEQ        1,
                        SIZE       5184000
                    },
                    [1] {
                        ADMID      "IMGPARAM00002",
                        CREATED    "2006-06-20T12:00:00",
                        FLocat     {
                            LOCTYPE      "URL",
                            xlink:href   "file://./003855/003855v.tif"
                        },
                        GROUPID    2,
                        ID         "IMG00002",
                        MIMETYPE   "image/tiff",
                        SEQ        2,
                        SIZE       5200228
                    }
                ],
                ID     "IMGGRP",
                USE    "Images"
            },
            [1] {
                file   [
                    [0] {
                        ADMID      "IMGPARAM00001",
                        CREATED    "2006-06-20T12:00:00",
                        FLocat     {
                            LOCTYPE      "URL",
                            xlink:href   "file://./003855/003855r.pdf"
                        },
                        GROUPID    1,
                        ID         "PDF00001",
                        MIMETYPE   "text/pdf",
                        SEQ        1,
                        SIZE       251967
                    },
                    [1] {
                        ADMID      "IMGPARAM00002",
                        CREATED    "2006-06-20T12:00:00",
                        FLocat     {
                            LOCTYPE      "URL",
                            xlink:href   "file://./003855/003855v.pdf"
                        },
                        GROUPID    2,
                        ID         "PDF00002",
                        MIMETYPE   "text/pdf",
                        SEQ        2,
                        SIZE       172847
                    }
                ],
                ID     "PDFGRP",
                USE    "PDF"
            }
        ]
    },
    xmlns:xlink   "http://www.w3.org/TR/xlink"
}