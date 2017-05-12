use strict;
use warnings;
use utf8;


package RussianTextGenerator;
use version; our $VERSION = qv('2.3.41');

sub new {
  my ( $classname ) = @_;
  my $self = {
    Prayer_for_the_living => "Молитва о живых",
    Prayer_for_the_departed => "Молитва о усопших",
    members => "Участники генеалогического дерева",
    Relatives => "Родственники",
    Faces => "Портреты",
    Surnames =>"Фамилии",
    Homepages => "Домашние страницы",
    homepage => "домашняя страница",
    Birthdays => "Дни рождения",
    birthday => "День рождения",
    Error => "Ошибка",
    Sorry => "Извините",  
    Passwd_need => "Вы должны ввести пароль, чтобы видеть эти страницы.",
    Wrong_passwd => "Вы дали неверный пароль для этих страниц.",
    
    father => "Отец",
    mother => "Мать",
    nickname => "Псевдоним",
    place_of_birth => "Место рождения",
    place_of_death =>"Место смерти",
    cemetery => "Кладбище",
    schools => "Школы",
    jobs => "Работы",
    work_places => "Места работы",
    places_of_living => "Места проживания",
    general => "Общий",
    
    siblings => "Родные Братья/Сестры",
    siblings_on_father => "Дети со стороны отца",
    siblings_on_mother => "Дети со стороны матери",
    children => "Дети",
    husbands => "Мужья",
    wives => "Жены",
    
    date_of_birth => "Дата рождения",
    date_of_death => "Дата смерти",
    Total => "Общее количество",
    people => "Люди",
    Emails => "Почтовые адреса",
    email => "Почтовый адрес",
    Hall_of_faces => "Галерея портретов",
    Total_with_email => "Общее количество людей с адресом электронной почты: ",
    Total_with_homepage => "Общее количество людей с домашней страницей: ",
    Total_with_photo => "Общее количество людей с фотографией: ",
    months_array => [ "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
      "Июль",    "Август",   "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"],
    Invalid_option => "Неврный тип параметра",
    Valid_options => "Доступные варианты <нет>, фамилии, лица, электронные письма, домашние страницы, дни рождения.",
    ZoomIn => "Увеличить",
    ZoomOut => "Уменьшить",
    CheckAnotherMonth => "Проверьте другой месяц",
    DonationSentence => "Программное обеспечение генеалогического дерева абсолютно свободно. Однако, чтобы держать его в живых помощь необходима.",
    Go => "Перейти",
    Unknown => "Неизвестный",
    name => "Имя",
    photo => "Фотография",
    man => "Мужчин",
    woman => "Женщин",
    unknown => "неизвестно",

    hungarian => "Венгерский",
    polish => "Польский",   
    english => "Английский",
    german => "Немецкий",
    spanish => "Испанский",
    italian => "Итальянский",
    french => "Французкий",
    slovenian => "Словенский",
    romanian => "Румынский",
    russian => "русский",
    japanese => "Японский",
    chinese => "Китайский",
  };
  return bless $self, $classname;
}

sub summary{
  my ($self, $nr_people) = @_;
  return "Всего: $nr_people человек \n";
}
sub maintainer {
    my ($self, $admin_name, $admin_email, $admin_webpage) = @_;
    my $text;
    $text = "Дерево поддерживает ";
    if(defined $admin_webpage) {
      $text .= "<a href=\"".$admin_webpage."\" target=\"_new\">".$admin_name."</a>";
    }
    else{
      $text .= $admin_name;
    }
    $text .= "- пожалуйста <a href=\"mailto:$admin_email\">по почте</a> сообщайте о корректировках или улучшениях.";
}
sub software {
  my ($self, $version) = @_;
  return "Family tree software (ver. $version) by <a href=\"http://www.cs.bme.hu/~bodon/en/index.html\" target=\"_new\">Ferenc Bodon</a> and ".
  "<a href=\"http://simonward.com/\"  target=\"_new\">Simon Ward</a>  and
  <a href=\"http://mishin.narod.ru/\"  target=\"_new\">Nikolay Mishin</a> - <a href=\"http://freshmeat.net/projects/familytree_cgi/\">details</a>.\n";
}
sub People_with_surname {
  my ($self, $surname) = @_;
  return "Люди с фамилией ".$surname;
} 
sub noDataAbout {
  my ($self, $id) = @_;
  return "ОШИБКА: Запись не найдена для $id";
}
sub familyTreeFor {
    my ($self, $name) = @_;
    return "Дерево для $name";
}
sub ZoomIn {
  my ($self, $level) = @_;
  return "Подробнее: показывает не более $level уровня родства.";
}
sub ZoomOut {
  my ($self, $level) = @_;
  return "Крупнее: показывает до $level уровней родства.";
}
sub birthday_reminder {
    my ($self, $month_index) = @_;
    return "Напоминание о дне рождения для ".$self->{months_array}[$month_index];
}

sub total_living_with_birthday {
    my ($self, $month_index) = @_;
    return "Общее число ныне здравствующих людей с днём рождения в ".$self->{months_array}[$month_index].": "; 
}

1;
