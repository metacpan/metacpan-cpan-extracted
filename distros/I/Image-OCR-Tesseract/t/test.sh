rm ./t/paragraph.tif
convert ./t/paragraph.jpg -compress none +matte ./t/paragraph.tif
identify ./t/paragraph.tif
tesseract ./t/paragraph.tif ./t/paragraph.tif

cat ./t/paragraph.tif.txt
ls -la ./t/paragraph.tif.txt
