(function () {
    'use strict';

    let URL_BACKEND, CAPTCHA_STYLE_NAME, ALT_IMAGE, captchetatComponent, ID_CAPTCHA;
    window.addEventListener('load', function () {
        // Récupère l'élément HTML
        captchetatComponent = document.getElementById("captchetat");

        // Vérifie si l'élément existe
        if (captchetatComponent) {
            URL_BACKEND = captchetatComponent.getAttribute('urlBackend');
            CAPTCHA_STYLE_NAME = captchetatComponent.getAttribute('captchaStyleName');
            ALT_IMAGE = captchetatComponent.getAttribute('altImage');
            getCaptcha();
        }
    });

    async function getCaptcha() {
        let url = URL_BACKEND + "?get=image&c=" + CAPTCHA_STYLE_NAME;
        await fetch(url, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            },
        })
            .then(response => {
                if (!response.ok) {
                    throw new Error('La réponse n\'est pas OK');
                }
                return response.json();
            })
            .then(data => {
                ID_CAPTCHA = data.uuid;
                constructHtml(data.imageb64);
                setButtonTitle();
            })
            .catch(error => {
                console.error('Erreur lors de la récupération du captcha', error);
            });
    }

    function setButtonTitle(){
        if (CAPTCHA_STYLE_NAME.includes('FR')){
            document.getElementById('playSoundIcon').setAttribute('title','Énoncer le code du captcha');
            document.getElementById('reloadCaptchaIcon').setAttribute('title','Générer un nouveau captcha');
        }
    }

    async function refreshCaptcha(){
        let url = URL_BACKEND + "?get=image&c=" + CAPTCHA_STYLE_NAME;
        await fetch(url, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            },
        })
            .then(response => {
                if (!response.ok) {
                    throw new Error('La réponse n\'est pas OK');
                }
                return response.json();
            })
            .then(data => {
                document.getElementById("captchaImage").src = data.imageb64;
                ID_CAPTCHA = data.uuid;
                document.getElementById("captchetat-uuid").setAttribute("value", ID_CAPTCHA);
            })
            .catch(error => {
                console.error('Erreur lors de la récupération du captcha', error);
            });
    }

    async function playCaptchaSound() {
        let url = URL_BACKEND + "?get=sound&c=" + CAPTCHA_STYLE_NAME + "&t=" + ID_CAPTCHA;
        try {
            await new Audio(url).play();
        } catch (error) {
            console.error('Erreur lors de la récupération du son');
            await refreshCaptcha();
        }
    }

    function constructHtml(imageb64) {
        const container = document.createElement('div');
        container.style.display = 'flex';
        container.style.flexDirection = 'row';
        container.id = 'captchetat-container';
        document.getElementById("captchetat").appendChild(container);

        const imgDiv = document.createElement('img');
        imgDiv.src = `${imageb64}`;
        imgDiv.alt = ALT_IMAGE ?? 'Recopier le code de sécurité de cette image';
        imgDiv.id = "captchaImage";
        document.getElementById("captchetat-container").appendChild(imgDiv);

        const logoDiv = document.createElement('div');
        logoDiv.id = "logos";
        logoDiv.style.marginLeft = "10px";
        logoDiv.style.display = "flex";
        logoDiv.style.flexDirection = "column";
        logoDiv.style.justifyContent = "space-evenly";
        document.getElementById("captchetat-container").appendChild(logoDiv);

        const buttonPlay = document.createElement('button');
        buttonPlay.type = "button";
        buttonPlay.id = "playSoundIcon";
        buttonPlay.title = "Speak the captcha code";
        buttonPlay.alt = "Enoncer le code du captcha";
        buttonPlay.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" version="1.0" width="25" height="25" viewBox="0 0 75 75"\n' +
            '                     id="iconSound">\n' +
            '                    <path d="M39.389,13.769 L22.235,28.606 L6,28.606 L6,47.699 L21.989,47.699 L39.389,62.75 L39.389,13.769z"\n' +
            '                          style="stroke:#111;stroke-width:5;stroke-linejoin:round;fill:#111;"/>\n' +
            '                    <path d="M48,27.6a19.5,19.5 0 0 1 0,21.4M55.1,20.5a30,30 0 0 1 0,35.6M61.6,14a38.8,38.8 0 0 1 0,48.6"\n' +
            '                          style="fill:none;stroke:#111;stroke-width:5;stroke-linecap:round"/>\n' +
            '                </svg>'
        document.getElementById("logos").appendChild(buttonPlay);
        document.getElementById("playSoundIcon").addEventListener('click', playCaptchaSound);


        const buttonRefresh = document.createElement('button');
        buttonRefresh.type = "button";
        buttonRefresh.id = "reloadCaptchaIcon";
        buttonRefresh.title = "Generate a new captcha";
        buttonRefresh.alt = "Générer un nouveau captcha";
        buttonRefresh.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="25" height="25" viewBox="0 0 17 20" fill="none"\n' +
            '                     id="iconReload">\n' +
            '                    <path d="M9.00003 4.0001C11.1 4.0001 13.1 4.8001 14.6 6.3001C17.7 9.4001 17.7 14.5001 14.6 17.6001C12.8 19.5001 10.3 20.2001 7.90003 19.9001L8.40003 17.9001C10.1 18.1001 11.9 17.5001 13.2 16.2001C15.5 13.9001 15.5 10.1001 13.2 7.7001C12.1 6.6001 10.5 6.0001 9.00003 6.0001V10.6001L4.00003 5.6001L9.00003 0.600098V4.0001ZM3.30003 17.6001C0.700029 15.0001 0.300029 11.0001 2.10003 7.9001L3.60003 9.4001C2.50003 11.6001 2.90003 14.4001 4.80003 16.2001C5.30003 16.7001 5.90003 17.1001 6.60003 17.4001L6.00003 19.4001C5.00003 19.0001 4.10003 18.4001 3.30003 17.6001V17.6001Z"\n' +
            '                          fill="black"/>\n' +
            '                </svg>'
        document.getElementById("logos").appendChild(buttonRefresh);
        document.getElementById("reloadCaptchaIcon").addEventListener('click', refreshCaptcha);

        const hiddenUuid = document.createElement('input');
        hiddenUuid.id = "captchetat-uuid";
        hiddenUuid.type = "hidden";
        hiddenUuid.value = ID_CAPTCHA;
        hiddenUuid.name = "captchetat-uuid";
        document.getElementById("captchetat").appendChild(hiddenUuid);
    }

    window.captchetatComponentModule = {          
        refreshCaptcha                             
        }  

}());

