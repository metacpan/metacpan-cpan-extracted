# CLDR Data Patches

These patches fix known upstream issues in CLDR XML files.

## cldr-48/supplementalData.xml.patch
- Issue: Missing 'h' in `ttps://...`
- CLDR Ticket: [CLDR-19101](https://unicode-org.atlassian.net/browse/CLDR-19101)
- Fixed: `uri` attribute in reference type="R1227"
