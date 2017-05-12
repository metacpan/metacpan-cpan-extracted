# Build softbank-unicode2sjisauto.yaml
./tools/softbank-scrape-autosjis.pl 103-111-HTML_2.0.0.txt > dat/softbank-unicode2sjis_auto.yaml

# NOTE
# You can use `rake' instead of all the following commands.

# Build YAML files
./tools/docomo-scrape.pl > dat/docomo-table.yaml
./tools/softbank-scrape.pl > dat/softbank-table.yaml
./tools/softbank-scrape-name.pl
./tools/kddi-extract.pl typeD.pdf > dat/kddi-table.yaml

# Update kddi/softbank yaml English names
./tools/add-names-by-mapping.pl dat/kddi-table.yaml
./tools/add-names-by-mapping.pl dat/softbank-table.yaml

# Make dat/*-table.pl for Charnames.pm
./tools/make-charnames-map.pl

# Build convert-utf8-map.yaml
./tools/convert-map-scrape.pl > dat/convert-map-utf8.yaml

# .yaml to .pl
./tools/yaml2perl.pl dat/docomo-table.pl dat/docomo-table.yaml
./tools/yaml2perl.pl dat/kddi-table.pl dat/kddi-table.yaml
./tools/yaml2perl.pl dat/softbank-table.pl dat/softbank-table.yaml
./tools/yaml2perl.pl dat/convert-map-utf8.pl dat/convert-map-utf8.yaml

# Make x-sjis-*.ucm
./tools/make-sjis-ucm.pl

# Make x-utf8-*.ucm
./tools/make-utf8-ucm.pl

# All set!
