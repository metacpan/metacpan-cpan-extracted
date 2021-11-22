
# Tracy
mkdir tracy
for i in *FOR*;
do
  tracy assemble $i ${i/FOR/REV} -o $(basename $i|  cut -f1 -d_)  && mv $(basename $i|  cut -f1 -d_).*.* tracy;
done

# ABi
mkdir this
for i in *FOR*;
do
   ../../bin/mergeabi $i ${i/FOR/REV} > this/$(basename $i|  cut -f1 -d_).fa
done
