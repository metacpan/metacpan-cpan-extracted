#!perl

use strict;
use warnings;

use Test::More tests => 2;

use_ok("File::RoundRobin");

{ # read beyond the end of line

	local $/ = undef;
	#seek(DATA,0,0);
    
    my $text = <DATA>;
    
    my $rrfile = File::RoundRobin->new(path => 'test.txt', size => '5M', autoflush => 1);
    
	$rrfile->write($text);
	
	
    my $rrfile2 = File::RoundRobin->new(path => 'test.txt', mode => 'read');

    my $content = '';
	while ( my $buffer = $rrfile2->read(10000) ) {
		$content .= $buffer;
        sleep 1;
	}
    
    $rrfile->close();
    $rrfile2->close();

    is(length($content),length($text),'File content read correctly');
	
	unlink('test.txt');
}




__DATA__
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Mauris sed neque mattis nulla fringilla auctor nec id neque.
Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
Pellentesque pharetra, lorem at fermentum adipiscing, quam lacus mollis justo, ac aliquet justo orci nec urna.
Aenean quis augue mi, volutpat dapibus tortor.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Morbi mollis metus nec turpis posuere placerat.
Sed nec elit turpis, eu interdum nisi.
Praesent non purus laoreet ipsum lacinia mollis sed ac mi.
Aenean luctus, elit vitae scelerisque euismod, leo diam pharetra mi, ac gravida eros risus at mi.
Maecenas et orci elit.
Praesent ipsum erat, tristique a imperdiet ut, tincidunt vitae libero.
Fusce at nisi vel nisi luctus auctor at eget metus.


Morbi ut quam ac arcu pharetra venenatis.
Proin facilisis leo non purus commodo aliquet.
Suspendisse porttitor vehicula metus, nec fringilla lectus ultricies eu.
Phasellus iaculis, lacus ac tempus suscipit, magna neque blandit purus, nec ullamcorper magna lectus in enim.
Vestibulum vehicula, dolor eu aliquam vehicula, tortor justo rhoncus purus, eget dignissim diam risus sodales odio.
Maecenas vulputate, quam sit amet semper faucibus, odio purus malesuada tellus, eu adipiscing magna ipsum non purus.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.


Etiam sed mollis sapien.
Vestibulum semper orci vel nunc facilisis dictum id at dui.
Praesent purus mi, scelerisque vitae sagittis vitae, tristique ac nibh.
Vivamus tristique augue eu sem tempor non sagittis ligula fermentum.
Nullam nec magna mi.
Nullam commodo auctor volutpat.
Donec dignissim velit ut orci feugiat id commodo tortor ultrices.
Cras convallis auctor lorem, in interdum elit auctor molestie.
Aliquam id sapien libero.
Etiam convallis egestas nisi, sit amet tristique eros blandit non.
Proin consectetur luctus risus vel posuere.
Nunc eu adipiscing augue.
Aenean lobortis arcu in mi blandit consequat.
Aenean vel mi eros.
In a eros ac mauris feugiat posuere.


Nam sed dolor leo, sed pellentesque diam.
Pellentesque auctor mi at lectus venenatis semper.
Cras a iaculis lacus.
Donec sollicitudin porttitor mauris, blandit pulvinar felis malesuada at.
Sed molestie feugiat odio ut porttitor.
Morbi risus turpis, molestie a porttitor in, condimentum nec lorem.
Cras ut neque justo.
Proin sed rutrum nunc.
Nunc felis lorem, gravida nec iaculis quis, sagittis porttitor metus.
Ut consectetur orci venenatis dui imperdiet vel mattis purus aliquam.
Cras auctor, purus et auctor aliquam, sapien tortor aliquet ipsum, at venenatis massa orci ut turpis.
Donec sed turpis mi.
Pellentesque vel felis in massa hendrerit pellentesque.
Fusce tempus sagittis enim, sit amet malesuada dui fringilla nec.
Maecenas in enim sed est pretium ultricies.


In metus metus, viverra vel fermentum at, accumsan sit amet nunc.
Curabitur magna justo, rhoncus a bibendum in, gravida vel justo.
Cras dictum tempor mauris vitae venenatis.
Nulla accumsan pulvinar interdum.
Sed facilisis interdum metus eget fermentum.
Vivamus eu tortor urna, feugiat tempor ipsum.
Cras ut neque mi, euismod consectetur neque.
Integer accumsan lacinia risus eu scelerisque.
Duis ornare vehicula elit.
Nullam sed aliquet neque.
Suspendisse luctus, mi eu lobortis posuere, ligula neque tempus diam, vel sodales est lacus vitae dolor.
Vestibulum id massa ut risus iaculis venenatis et quis augue.
Vestibulum accumsan vestibulum nulla vel venenatis.


Curabitur tincidunt lorem et nunc sagittis ac iaculis leo dapibus.
Nunc ac pellentesque justo.
Proin ornare, justo et mattis suscipit, nulla libero interdum lacus, at rhoncus ante ipsum vitae lacus.
Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
Proin diam tortor, blandit non cursus a, dignissim non lectus.
Sed auctor facilisis suscipit.
Mauris elementum velit id ipsum faucibus pulvinar.
Nulla facilisi.


Quisque rhoncus euismod nisl ac egestas.
Curabitur sed nulla ut nibh cursus viverra lobortis sit amet metus.
Ut mauris ipsum, tempus quis volutpat in, sollicitudin ac libero.
Quisque rutrum porta arcu quis convallis.
Donec lorem tortor, malesuada in ultricies ut, rhoncus ac velit.
Cras elementum sodales blandit.
Aliquam a felis magna.


Mauris nulla est, faucibus eu sagittis id, ultricies sed tellus.
Duis placerat viverra dapibus.
Vestibulum laoreet tellus rhoncus leo molestie sit amet vulputate est iaculis.
Morbi erat dui, auctor nec vulputate id, molestie id nunc.
Aenean imperdiet ante eu ante volutpat a auctor felis porttitor.
Phasellus sed nisi in ligula pellentesque fermentum viverra ut est.
Maecenas eleifend auctor eleifend.
Nunc id nulla quis nunc scelerisque gravida.
Cras interdum faucibus velit, tempus ornare ligula facilisis sit amet.
Nulla rutrum bibendum mi ut varius.
Aliquam mollis libero sit amet nisi consequat sollicitudin sit amet vel lorem.
Aliquam imperdiet imperdiet porttitor.
Suspendisse at lorem ac lacus vehicula facilisis id sit amet lorem.


Nulla eu scelerisque libero.
Aliquam sagittis rhoncus diam, et rutrum ipsum malesuada a.
Aenean metus felis, accumsan a malesuada quis, mattis vitae tortor.
In nunc est, commodo et imperdiet quis, posuere vitae massa.
Maecenas eget urna non enim pulvinar pharetra et accumsan erat.
Cras laoreet sagittis nisi, eget lobortis quam ornare sit amet.
Vestibulum sit amet tristique nunc.
Maecenas mollis orci ut quam malesuada ullamcorper.
Fusce sed arcu ut lorem vulputate viverra eu egestas leo.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Aenean eget malesuada dolor.
Cras mollis feugiat justo, vitae consectetur turpis volutpat ac.


Vivamus scelerisque consectetur nunc.
Nullam sit amet leo tellus, at lobortis libero.
Curabitur facilisis placerat orci, at aliquet diam tincidunt non.
Cras nisl tellus, semper et iaculis eu, blandit et lacus.
Quisque sit amet sem non nisi vulputate interdum non id augue.
Donec a lorem dolor, quis suscipit augue.
Integer gravida purus vitae justo rhoncus volutpat.
Cras aliquam lacus quis ipsum mattis interdum.
Donec pulvinar aliquet suscipit.
Duis accumsan purus eget purus sodales sit amet ultrices purus lobortis.
Donec ligula felis, bibendum eu lacinia nec, eleifend placerat libero.
Curabitur ac ipsum diam.
In est risus, facilisis non porttitor vel, fringilla id turpis.
Cras consequat fringilla urna non ornare.
Nulla sed metus nisl.


Mauris urna dolor, molestie non euismod eu, elementum eget mauris.
Nam adipiscing viverra placerat.
Suspendisse elementum adipiscing massa id vulputate.
Sed posuere ligula ut justo fermentum convallis.
Nulla viverra pulvinar velit vehicula dignissim.
Mauris aliquam tellus libero.
Cras venenatis dolor nunc, nec accumsan libero.
Fusce nec commodo est.
Integer congue pulvinar sem, id ullamcorper orci sagittis eget.
Cras et gravida est.
Etiam porttitor nisl sit amet neque malesuada pulvinar.
Cras pulvinar sapien tincidunt justo laoreet egestas hendrerit magna porta.
Pellentesque eu elit sapien.
Curabitur non turpis ut odio ultricies tempor non nec est.


Nullam fermentum auctor eleifend.
Ut semper pharetra turpis in semper.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Fusce in nibh id risus mollis elementum.
Nulla est libero, ullamcorper imperdiet volutpat vel, pharetra at est.
Donec felis urna, viverra sit amet ultricies a, consequat ac dolor.
Suspendisse dictum egestas odio vitae semper.
Fusce non ipsum nec tortor molestie cursus eget vitae ligula.
Sed vel orci condimentum odio convallis malesuada ut nec lacus.
Mauris placerat eleifend risus.
Quisque lacinia fermentum nisl in placerat.
Praesent lacinia, ante pulvinar auctor lacinia, purus est dapibus diam, eget laoreet dui odio eu velit.
Donec non nunc eget sem condimentum pulvinar.
In ac elementum lectus.
Mauris ut ipsum dapibus metus ultrices venenatis et eget felis.


Donec ante enim, faucibus ac viverra vitae, faucibus eu diam.
Integer ac nulla dolor, ultrices dignissim diam.
Suspendisse potenti.
Proin convallis risus a ante pharetra ut fermentum risus gravida.
Aliquam non vulputate mi.
Donec hendrerit tempor lacus, vel ultricies augue egestas non.
Proin massa lorem, ullamcorper vitae elementum vitae, rutrum vel urna.
Nunc vitae mauris vitae nulla adipiscing tempus.
Proin mi elit, mollis eu blandit lacinia, scelerisque ut nibh.
Nunc molestie velit volutpat quam viverra convallis.
Mauris erat ligula, fermentum a sollicitudin eget, imperdiet venenatis lacus.
Sed eu sem eu mi malesuada egestas ut vel purus.
Nunc eget ante lectus, in convallis tellus.
Aliquam vulputate venenatis nibh, id tincidunt justo vulputate ac.


Quisque commodo mattis diam eu ornare.
Proin rutrum purus ligula.
Aliquam euismod, lorem vel pretium viverra, nisl eros bibendum turpis, sed ultrices eros velit vitae felis.
Nulla porttitor scelerisque augue, dapibus faucibus ligula commodo nec.
Mauris at lectus felis.
Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.
Sed euismod sollicitudin enim, ac bibendum erat lacinia ut.
Vestibulum et augue eleifend tellus congue consectetur.
Nam blandit tincidunt mattis.
Aenean vitae est dui.
Sed lacinia nisl vitae est posuere commodo.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.


Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.
Suspendisse eu lorem et elit placerat feugiat.
Quisque quis est tellus, eget laoreet magna.
Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.
Quisque non ligula mauris.
Aenean sollicitudin luctus urna, ac vulputate tellus ultrices ut.
Nullam ut sapien nunc, ut venenatis ante.


Curabitur rutrum quam nec augue ultrices suscipit auctor sed leo.
Nulla quam nunc, vehicula in tempor ac, ornare eget ligula.
Nullam nec quam eu purus mattis egestas in nec urna.
Nam bibendum est sit amet nisl aliquam quis lacinia urna laoreet.
Etiam et purus vitae est lobortis pharetra.
Suspendisse potenti.
Donec sed mi at odio mollis dapibus.
Sed velit eros, tincidunt sit amet elementum sit amet, suscipit tincidunt neque.
Pellentesque sit amet velit non enim interdum condimentum.


Donec sem lacus, viverra id pharetra sit amet, aliquam et turpis.
Integer ullamcorper placerat leo a sodales.
Sed vitae luctus risus.
Nulla venenatis, erat nec auctor elementum, lacus arcu convallis ligula, sed sollicitudin leo neque eget neque.
Aenean eget lacus metus.
Vivamus molestie est eu elit condimentum molestie.
Nunc eget tellus lectus, ac elementum eros.
Pellentesque auctor lectus in massa mattis adipiscing.
Vestibulum elementum massa sed odio lacinia sodales congue tellus commodo.
In tincidunt justo eu lacus tristique sed lobortis justo faucibus.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.


Morbi tortor elit, tempor at imperdiet a, posuere quis ante.
Duis ultrices sem at diam convallis id interdum ligula condimentum.
Sed volutpat tincidunt ornare.
Praesent mauris mauris, placerat vitae fringilla at, hendrerit vitae sapien.
Aenean metus ipsum, vulputate sed commodo sed, fringilla non neque.
Maecenas rhoncus mi quis sapien lobortis semper.
Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Vivamus quis magna at tortor vehicula commodo.
Pellentesque a tellus velit, a viverra quam.
Integer tempus ante purus, at euismod dui.


In tellus sem, mattis a porta vel, accumsan vel elit.
Cras in diam a tortor ultrices suscipit.
Proin et lectus neque.
Ut consequat tortor sed nisi adipiscing eleifend eu in dolor.
Fusce iaculis bibendum arcu eu mattis.
Nulla lobortis feugiat dolor, sed hendrerit orci pulvinar eget.
Duis vel diam ac est luctus hendrerit.
Maecenas ut feugiat eros.
Integer vulputate dictum magna, vel cursus nunc consequat non.
Maecenas eros odio, placerat eget sagittis condimentum, lobortis vel diam.
In hac habitasse platea dictumst.
Proin sit amet velit in felis facilisis porta.


Maecenas justo justo, semper at tristique eu, varius in leo.
Praesent venenatis, sapien sed condimentum ultrices, sem mi faucibus velit, ut bibendum urna odio et lorem.
Aenean sem mauris, sodales nec porttitor eget, iaculis vitae sem.
Aenean porta dapibus blandit.
Ut porta, sapien vitae facilisis condimentum, ipsum lectus ultrices tellus, ut consequat sem odio sed nibh.
Nullam vel arcu sed.
